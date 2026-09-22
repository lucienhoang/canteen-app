/// Lớp đại diện cho Món ăn/Thức uống trong thực đơn.
class MenuItem {
  /// Mã định danh duy nhất của món
  final int id;

  /// Mã danh mục liên kết với [Category] (món này thuộc nhóm nào)
  final int categoryId;

  /// Tên món ăn / thức uống
  final String name;

  /// Giá bán của món (Đơn vị: VND)
  final int price;

  /// Trạng thái phục vụ: [true] nếu còn bán, [false] nếu đã hết hàng
  final bool isAvailable;

  /// Hàm khởi tạo cố định (const) cho MenuItem.
  /// Mặc định [isAvailabel] là [true] nếu không được truyền vào.
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });
}
