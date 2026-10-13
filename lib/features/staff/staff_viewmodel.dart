import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';

import '../../data/repositories/order_repository_exception.dart';

/// Quản lý danh sách đơn hàng cho màn hình nhân viên căn tin.
/// Nhân viên xem tất cả các đơn (không lọc theo user) và cập nhật trạng thái đơn.
class StaffViewModel extends ChangeNotifier {
  /// [_onStatusChanged] được gọi sau khi đổi trạng thái thành công.
  /// Mặc định gửi thông báo thật; khi test có thể truyền hàm giả vào để
  /// không phụ thuộc plugin Android.
  StaffViewModel({required this._orderRepository, this._onStatusChanged});

  final OrderRepository _orderRepository;

  /// Hàm tùy chọn gọi sau khi đổi trạng thái thành công (mặc định không làm gì).
  /// Thông báo cho sinh viên do máy sinh viên tự lo (xem OrderStatusWatcher).
  final Future<void> Function(Order order)? _onStatusChanged;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Order>>? _ordersSubscription;

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

  /// Bắt đầu theo dõi đơn hàng theo thời gian thực: danh sách tự cập nhật mỗi khi
  /// có đơn mới hoặc đơn đổi trạng thái, không cần tải lại thủ công.
  /// Gọi nhiều lần cũng chỉ đăng ký một lần.
  void startWatching() {
    if (_ordersSubscription != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _ordersSubscription = _orderRepository.watchAllOrders().listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('Theo dõi đơn hàng lỗi: $e\n$st');
        _isLoading = false;
        _errorMessage = e is OrderRepositoryException
            ? e.message
            : "Không tải được danh sách đơn, thử lại nhé";
        notifyListeners();
      },
    );
  }

  /// Tải một lần tất cả các đơn hàng từ hệ thống (không theo dõi liên tục).
  /// Dùng khi chưa gọi [startWatching], hoặc để thử lại thủ công.
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
  /// Đổi trạng thái là phần chính; gửi thông báo là phần phụ nên nếu thông báo
  /// lỗi thì không được làm hỏng luồng chính.
  Future<void> changeStatus(Order order, OrderStatus newStatus) async {
    if (!order.status.canChangeTo(newStatus)) return;
    _errorMessage = null;

    try {
      await _orderRepository.updateOrderStatus(order.id!, newStatus);
    } on OrderRepositoryException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return;
    } catch (e) {
      _errorMessage = "Cập nhật trạng thái thất bại, thử lại nhé";
      notifyListeners();
      return;
    }

    // Đang theo dõi thì stream tự đẩy danh sách mới về, không cần tải lại.
    // Chưa theo dõi thì tải lại thủ công như trước.
    if (_ordersSubscription == null) {
      await loadOrders();
    }

    final onStatusChanged = _onStatusChanged;

    if (onStatusChanged != null) {
      try {
        await onStatusChanged(order.copyWith(status: newStatus));
      } catch (e) {
        debugPrint('Gửi thông báo thất bại: $e');
      }
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
