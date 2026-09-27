import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';

/// Quản lý danh sách đơn hàng cho màn hình nhân viên căn tin.
/// Nhân viên xem tất cả các đơn (không lọc theo user) và cập nhật trạng thái đơn.
class StaffViewModel extends ChangeNotifier {
  StaffViewModel({required this._orderRepository});

  final OrderRepository _orderRepository;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Chỉ hiện đơn đang cần xử lý (bỏ qua đã hoàn thành / đã hủy) để nhân viên
  /// tập trung vào công việc hiện tại, không bị rối bởi các đơn cũ.
  List<Order> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  /// Trạng thái đang tải danh sách đơn từ database
  bool get isLoading => _isLoading;

  /// Thông báo lỗi nếu có
  String? get errorMessage => _errorMessage;

  /// Tải tất cả các đơn hàng từ hệ thống
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderRepository.getAllOrders();
    } catch (e) {
      _errorMessage = "Không tải được danh sách đơn, thử lại nhé";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật trạng thái 1 đơn, chỉ cho phép nếu hợp lệ theo [OrderStatus.canChangeTo].
  /// Sau khi đổi thành công, tự động tải lại danh sách để đồng bộ UI.
  Future<void> changeStatus(Order order, OrderStatus newStatus) async {
    if (!order.status.canChangeTo(newStatus)) return;

    try {
      await _orderRepository.updateOrderStatus(order.id!, newStatus);
      await loadOrders();
    } catch (e) {
      _errorMessage = "Cập nhật trạng thái thất bại, thử lại nhé";
      notifyListeners();
    }
  }
}
