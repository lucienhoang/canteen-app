/// Lớp đại diện cho một danh mục (Category) trong app.
class Category {
  /// Mã định danh duy nhất của danh mục.
  final int id;

  /// Tên hiển thị danh mục.
  final String name;

  /// Hàm khởi tạo cố định (const) cho Category.
  /// Bắt buộc phải truyền đầy đủ [id] và [name]
  const Category({required this.id, required this.name});
}
