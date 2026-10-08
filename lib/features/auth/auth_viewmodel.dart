import 'package:flutter/foundation.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

/// Trạng thái xác thực của app.
enum AuthStatus {
  /// Vừa mở app, đang kiểm tra xem có phiên đăng nhập sẵn không.
  checking,
  signedOut,
  signedIn,
}

/// Giữ người đang đăng nhập và xử lý đăng nhập / đăng xuất.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Gọi 1 lần lúc mở app: khôi phục phiên đăng nhập nếu có.
  Future<void> restoreSession() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      _status = _currentUser == null
          ? AuthStatus.signedOut
          : AuthStatus.signedIn;
    } catch (e, st) {
      debugPrint('Khôi phục phiên lỗi: $e\n$st');
      _currentUser = null;
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  /// Trả về true nếu đăng nhập thành công.
  Future<bool> signIn(String loginId, String password) async {
    if (_isLoading) return false; // chặn bấm liên tiếp

    if (loginId.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã số và mật khẩu';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.signIn(
        loginId: loginId,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.signedIn;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e, st) {
      debugPrint('Đăng nhập lỗi: $e\n$st');
      _errorMessage = 'Đăng nhập thất bại, thử lại nhé';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e, st) {
      debugPrint('Đăng xuất lỗi: $e\n$st');
    }
    // Dù repository lỗi, phía app vẫn coi như đã đăng xuất.
    _currentUser = null;
    _status = AuthStatus.signedOut;
    _errorMessage = null;
    notifyListeners();
  }
}
