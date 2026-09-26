import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

/// ViewModel quản lý trạng thái màn hình Theo dõi chi tiết 1 Đơn hàng cụ thể.
/// Nhận dữ liệu read-only từ SQLite sau khi đơn đã được tạo thành công.
class OrderTrackingViewModel extends ChangeNotifier {
  /// Khởi tạo ViewModel với [OrderRepository]
  OrderTrackingViewModel({required this._orderRepository});

  final OrderRepository _orderRepository;

  Order? _order;
  bool _isLoading = false;
  String? _errorMessage;

  /// Đối tượng đơn hàng hiện tại
  Order? get order => _order;

  /// Trạng thái đang nạp dữ liệu từ database
  bool get isLoading => _isLoading;

  /// Thông báo lỗi khi không thể nạp thông tin đơn
  String? get errorMessage => _errorMessage;

  /// Tải thông tin chi tiết của đơn hàng theo [orderId] từ cơ sở dữ liệu
  Future<void> loadOrder(int orderId) async {
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
}
