import '../../core/network/connectivity_service.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'order_repository.dart';
import 'order_repository_exception.dart';

/// Bọc ngoài một [OrderRepository] khác (mẫu thiết kế Decorator).
///
/// - Hàm GHI (tạo đơn, đổi trạng thái): đang offline thì từ chối ngay, không
///   gọi repository bên trong. Đơn chưa tới được căn tin thì không nên để
///   người dùng tưởng đã đặt xong.
/// - Hàm ĐỌC và theo dõi: chuyển tiếp thẳng. Offline vẫn xem được dữ liệu
///   đã lưu trong cache.
class ConnectivityGuardedOrderRepository implements OrderRepository {
  ConnectivityGuardedOrderRepository(this._inner, this._connectivity);

  final OrderRepository _inner;
  final ConnectivityService _connectivity;

  static const String offlineMessage =
      'Không có kết nối mạng, kiểm tra rồi thử lại nhé';

  Future<void> _ensureOnline() async {
    if (!await _connectivity.isOnline()) {
      throw const OrderRepositoryException(offlineMessage);
    }
  }

  // ---------------------------------------------------------------- ghi

  @override
  Future<Order> createOrder(Order order) async {
    await _ensureOnline();
    return _inner.createOrder(order);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _ensureOnline();
    return _inner.updateOrderStatus(orderId, newStatus);
  }

  // ---------------------------------------------------------------- đọc

  @override
  Future<List<Order>> getOrdersByUser(String userId) =>
      _inner.getOrdersByUser(userId);

  @override
  Future<Order?> getOrderById(String id) => _inner.getOrderById(id);

  @override
  Future<List<Order>> getAllOrders() => _inner.getAllOrders();

  @override
  Stream<List<Order>> watchAllOrders() => _inner.watchAllOrders();

  @override
  Stream<Order?> watchOrder(String id) => _inner.watchOrder(id);

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) =>
      _inner.watchOrdersByUser(userId);
}
