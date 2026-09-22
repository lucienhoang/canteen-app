import 'menu_item.dart';

/// Lớp dại diện cho Một dòng món trong đơn hàng (Order).
///
/// Khác với [MenuItem], [OrderItem] lưu lại [menuItemName] và [priceAtOrder]
/// tại đúng thời điểm khách đặt hàng — để sau này nếu tên hoặc giá món
/// trong thực đơn thay đổi, đơn hàng cũ vẫn hiển thị đúng như lúc đặt.
class OrderItem {
  /// Mã định danh duy nhất của dòng đơn hàng.
  /// [null] khi chưa được lưu vào CSDL.
  final int? id;

  /// Mã món liên kết với [MenuItem] gốc trong thực đơn.
  final int menuItemId;

  /// Tên món tại thời điểm đặt hàng (không đổi dù thực đơn có đổi tên sau này).
  final String menuItemName;

  /// Giá của món tại thời điểm đặt hàng
  final int priceAtOrder;

  /// Số lượng món được đặt
  final int quantity;

  /// Hàm khởi tạo cố định cho OrderItem
  const OrderItem({
    this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.priceAtOrder,
    required this.quantity,
  }) : assert(quantity > 0, 'Số lượng phải lớn hơn 0');

  /// Thành tiền của riêng dòng này = giá tại thời điểm đặt x số lượng
  int get subtotal => priceAtOrder * quantity;

  /// Tạo bảng sao của [OrderItem], chỉ thay field nào được truyền vào.
  OrderItem copyWith({
    int? id,
    int? menuItemId,
    String? menuItemName,
    int? priceAtOrder,
    int? quantity,
  }) {
    return OrderItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      priceAtOrder: priceAtOrder ?? this.priceAtOrder,
      quantity: quantity ?? this.quantity,
    );
  }
}
