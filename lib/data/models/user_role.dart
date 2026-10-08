/// Vai trò của người dùng trong hệ thống Canteen App.
enum UserRole {
  student,
  staff;

  /// Tên hiển thị giao diện tương ứng với từng vai trò.
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Sinh viên';
      case UserRole.staff:
        return 'Nhân viên';
    }
  }

  /// Đọc role từ chuỗi lưu trong Firestore/DB.
  /// Nếu giá trị [name] bị null hoặc không hợp lệ -> Mặc định gán về [UserRole.student]
  /// để tránh vô tình cấp nhầm quyền nhân viên khi dữ liệu gặp sự cố.
  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => UserRole.student,
    );
  }
}
