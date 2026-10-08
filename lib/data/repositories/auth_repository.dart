import '../models/app_user.dart';
import '../models/user_role.dart';

/// Lỗi xác thực có thông báo thân thiện để hiển thị lên giao diện (UI).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Hợp đồng xác thực (Interface/Contract).
/// ViewModel chỉ làm việc với lớp này, tách biệt hoàn toàn nguồn dữ liệu (Mock hay Firebase Auth).
abstract class AuthRepository {
  /// Đăng nhập bằng mã số (MSSV/Mã NV) + Mật khẩu.
  /// Sai thông tin sẽ ném ra [AuthException].
  Future<AppUser> signIn({required String loginId, required String password});

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut();

  /// Lấy thông tin người dùng đang đăng nhập hiện tại, trả về null nếu chưa đăng nhập
  Future<AppUser?> getCurrentUser();
}

class _MockAccount {
  const _MockAccount(this.user, this.password);

  final AppUser user;
  final String password;
}

/// Bản giả lập (Mock) dùng cho Unit Test và thử nghiệm khi chưa kết nối Firebase Auth.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    for (final account in _seedAccounts) {
      _accounts[account.user.mssv.toLowerCase()] = account;
    }
  }

  // Danh sách tài khoản giả lập ban đầu
  static const _seedAccounts = [
    _MockAccount(
      AppUser(
        id: 'student-1',
        name: 'Nguyễn Văn A',
        mssv: '2110001',
        role: UserRole.student,
      ),
      '123456',
    ),
    _MockAccount(
      AppUser(
        id: 'student-2',
        name: 'Trần Thị B',
        mssv: '2110002',
        role: UserRole.student,
      ),
      '123456',
    ),
    _MockAccount(
      AppUser(
        id: 'staff-1',
        name: 'Cô Lan (căn tin)',
        mssv: 'NV01',
        role: UserRole.staff,
      ),
      'staff123',
    ),
  ];

  final Map<String, _MockAccount> _accounts = {};
  AppUser? _currentUser;

  @override
  Future<AppUser> signIn({
    required String loginId,
    required String password,
  }) async {
    final account = _accounts[loginId.trim().toLowerCase()];

    // Dùng chung 1 câu thông báo lỗi để bảo mật, tránh lộ thông tin MSSV nào đã tồn tại
    if (account == null || account.password != password) {
      throw const AuthException('Sai mã số hoặc mật khẩu');
    }

    _currentUser = account.user;
    return account.user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;
}
