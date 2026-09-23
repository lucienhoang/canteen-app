import 'package:flutter/foundation.dart';

import '../../data/models/menu_item.dart';
import '../../data/models/order.dart';
import '../../data/models/order_item.dart';
import '../../data/repositories/order_repository.dart';

/// Quản lý trạng thái giỏ hàng tạm thời (trên RAM) và xử lý luồng đặt đơn (Checkout).
///
/// Giỏ hàng lưu danh sách [OrderItem] thay vì [MenuItem] để chốt giá ([priceAtOrder])
/// ngay tại thời điểm khách hàng bấm chọn món.
class CartViewModel extends ChangeNotifier {
  /// Hàm khởi tạo nhận vào [OrderRepository]
  CartViewModel({required this._orderRepository});

  final OrderRepository _orderRepository;

  // --- Trạng thái nội bộ (Private States) ---
  final List<OrderItem> _items = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  // --- Getters an toàn cho tầng UI ---

  /// Danh sách các món trong giỏ (không thể chỉnh sửa trực tiếp từ bên ngoài)
  List<OrderItem> get items => List.unmodifiable(_items);

  /// Trạng thái đang gửi đơn hàng lên hệ thống
  bool get isSubmitting => _isSubmitting;

  /// Thông báo lỗi trong quá trình đặt đơn (nếu có)
  String? get errorMessage => _errorMessage;

  /// Kiểm tra giỏ hàng có đang trống hay không
  bool get isEmpty => _items.isEmpty;

  /// Tổng tiền của toàn bộ giỏ hàng = cộng dồn [subtotal] của từng dòng
  int get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  /// Thêm 1 món từ Thực đơn vào giỏ hàng.
  /// Nếu món đã tồn tại trong giỏ thì tăng số lượng [quantity] thêm 1
  void addItem(MenuItem item) {
    final index = _items.indexWhere((i) => i.menuItemId == item.id);

    if (index != -1) {
      // Món đã có trong giỏ -> Tăng số lượng
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    } else {
      // Món chưa có trong giỏ -> Chốt giá và tạo dòng OrderItem mới
      _items.add(
        OrderItem(
          menuItemId: item.id,
          menuItemName: item.name,
          priceAtOrder: item.price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  /// Xóa hẳn một dòng món khỏi giỏ hàng dựa theo [menuItemId]
  void removeItem(int menuItemId) {
    _items.removeWhere((i) => i.menuItemId == menuItemId);
    notifyListeners();
  }

  /// Cập nhật số lượng của một món trong giỏ.
  /// Nếu [quantity] <= 0, hệ thống sẽ tự động xóa món đó khỏi giỏ.
  void updateQuantity(int menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    final index = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(quantity: quantity);
    notifyListeners();
  }

  /// Xóa sạch toàn bộ món trong giỏ hàng
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Tạo đơn hàng chính thức từ giỏ hiện tại và lưu qua [OrderRepository].
  /// Trả về [Order] đã tạo thành công, hoặc [null] nếu xảy ra lỗi.
  Future<Order?> checkout({
    required int userId,
    required DateTime pickupTime,
    String? note,
  }) async {
    // 1. Kiểm tra giỏ hàng trống
    if (_items.isEmpty) {
      _errorMessage = "Giỏ hàng đang trống!";
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners(); // Báo UI bật trạng thái loading/submit

    try {
      // 2. Gọi Repository tạo Order
      final order = await _orderRepository.createOrder(
        Order(
          userId: userId,
          items: List.of(_items),
          pickupTime: pickupTime,
          note: note,
          createdAt: DateTime.now(),
        ),
      );

      // 3. Đặt đơn thành công -> Xóa sạch giỏ hàng
      clear();
      return order;
    } catch (e) {
      _errorMessage = "Đặt đơn thất bại, xin hãy thử lại sau!";
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners(); // Báo UI tắt trạng thái submit
    }
  }
}
