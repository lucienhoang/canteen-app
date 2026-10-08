import 'user_role.dart';

/// Người dùng đã đăng nhập vào hệ thống Canteen App.
/// [id] tương ứng với Firebase Auth UID / Firestore Document ID.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.mssv,
    required this.role,
  });

  final String id;
  final String name;

  /// Mã số sinh viên (hoặc Mã nhân viên)
  final String mssv;
  final UserRole role;

  /// Getter kiểm tra xem người dùng có phải nhân viên căn tin không
  bool get isStaff => role == UserRole.staff;

  /// Chuyển đối tượng thành Map để lưu vào document `users/{id}` trên Firestore.
  /// Không bao gồm [id] vì [id] đóng vai trò là Document ID.
  Map<String, dynamic> toMap() => {
    'name': name,
    'mssv': mssv,
    'role': role.name,
  };

  /// Khởi tạo [AppUser] từ dữ liệu Document snapshot trên Firestore
  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      mssv: map['mssv'] as String? ?? '',
      role: UserRole.fromName(map['role'] as String?),
    );
  }
}
