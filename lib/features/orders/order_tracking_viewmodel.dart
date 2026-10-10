import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

/// ViewModel quản lý trạng thái màn hình Theo dõi chi tiết 1 Đơn hàng cụ thể.
/// Theo dõi đơn theo thời gian thực: nhân viên đổi trạng thái thì màn hình tự cập nhật.
class OrderTrackingViewModel extends ChangeNotifier {
  /// Khởi tạo ViewModel với [OrderRepository]
  OrderTrackingViewModel({required this._orderRepository});

  final OrderRepository _orderRepository;

  Order? _order;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Order?>? _subscription;

  /// Đối tượng đơn hàng hiện tại
  Order? get order => _order;

  /// Trạng thái đang nạp dữ liệu từ database
  bool get isLoading => _isLoading;

  /// Thông báo lỗi khi không thể nạp thông tin đơn
  String? get errorMessage => _errorMessage;

  /// Bắt đầu theo dõi đơn [orderId]: nhận đơn hiện tại ngay, rồi nhận lại
  /// mỗi khi đơn thay đổi. Gọi lại với id khác thì chuyển sang theo dõi đơn mới.
  void watchOrder(String orderId) {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _orderRepository
        .watchOrder(orderId)
        .listen(
          (order) {
            _isLoading = false;
            if (order == null) {
              _errorMessage = "Không tìm thấy đơn hàng";
            } else {
              _order = order;
              _errorMessage = null;
            }
            notifyListeners();
          },
          onError: (Object e, StackTrace st) {
            debugPrint('Theo dõi đơn lỗi: $e\n$st');
            _isLoading = false;
            _errorMessage = "Không tải được thông tin đơn, thử lại nhé";
            notifyListeners();
          },
        );
  }

  /// Tải thông tin chi tiết của đơn hàng theo [orderId] một lần (không theo dõi liên tục).
  Future<void> loadOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _orderRepository.getOrderById(orderId);
      if (result == null) {
        _errorMessage = "Không tìm thấy đơn hàng";
      } else {
        _order = result;
      }
    } catch (e) {
      _errorMessage = "Không tải được thông tin đơn, thử lại nhé";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
