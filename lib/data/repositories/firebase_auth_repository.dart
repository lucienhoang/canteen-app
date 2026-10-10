import 'package:cloud_firestore/cloud_firestore.dart';
// Dùng tiền tố `fb` để tách khỏi các tên của app (AppUser, AuthException...)
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

/// Đăng nhập thật bằng Firebase Auth, vai trò lấy từ Firestore `users/{uid}`.
///
/// Firebase Auth đòi định dạng email, nên mã số người dùng gõ vào được ghép
/// thành `mssv@canteen.local` ở bên trong lớp này. ViewModel và UI không cần biết.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? fb.FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static const _emailDomain = 'canteen.local';
  static const _usersCollection = 'users';

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Ghép mã số thành email. Không phân biệt hoa thường, bỏ khoảng trắng hai đầu.
  @visibleForTesting
  static String toEmail(String loginId) =>
      '${loginId.trim().toLowerCase()}@$_emailDomain';

  /// Đổi mã lỗi của Firebase thành thông báo thân thiện.
  /// Mọi lỗi "sai thông tin" dùng chung một câu để không lộ mã số nào tồn tại.
  @visibleForTesting
  static String messageForCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
        return 'Sai mã số hoặc mật khẩu';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa, liên hệ quản trị viên';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng đợi một lát rồi thử lại';
      case 'network-request-failed':
        return 'Không có kết nối mạng, kiểm tra lại rồi thử lại nhé';
      default:
        return 'Đăng nhập thất bại, thử lại nhé';
    }
  }

  @override
  Future<AppUser> signIn({
    required String loginId,
    required String password,
  }) async {
    // Bước 1: xác thực mã số + mật khẩu với Firebase Auth
    final fb.UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: toEmail(loginId),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(messageForCode(e.code));
    }

    // Bước 2: đọc hồ sơ (tên, mã số, vai trò) từ Firestore
    try {
      final user = await _loadProfile(credential.user!.uid);
      if (user == null) {
        // Có tài khoản Auth nhưng chưa có hồ sơ -> không cho vào,
        // và đăng xuất để không giữ phiên "lửng lơ".
        await _auth.signOut();
        throw const AuthException(
          'Tài khoản chưa được cấp quyền sử dụng, liên hệ quản trị viên',
        );
      }
      return user;
    } on FirebaseException catch (e) {
      debugPrint('Không tải được hồ sơ người dùng: ${e.code}');
      await _auth.signOut();
      throw AuthException(
        e.code == 'unavailable'
            ? messageForCode('network-request-failed')
            : 'Không tải được thông tin tài khoản, thử lại nhé',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> getCurrentUser() async {
    // authStateChanges().first chờ Firebase khôi phục phiên xong
    // (đáng tin hơn đọc currentUser ngay, nhất là trên web).
    final firebaseUser = await _auth.authStateChanges().first;
    if (firebaseUser == null) return null;

    final user = await _loadProfile(firebaseUser.uid);
    if (user == null) await _auth.signOut();
    return user;
  }

  Future<AppUser?> _loadProfile(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(uid, data);
  }
}
