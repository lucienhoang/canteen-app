import '../models/order.dart';
import '../models/order_status.dart';

/// Hợp đồng quy định các thao tác bắt buộc phải có để lưu/đọc Đơn hàng.
/// Sau này sẽ có thêm SqliteOrderRepository triển khai bằng sqflite,
/// thay thế MockOrderRepository mà không cần sửa ViewModel/Screen.
abstract class OrderRepository {
  /// Lưu đơn hàng mới, trả về [Order] đã được gán [id] chính thức.
  Future<Order> createOrder(Order order);

  /// Lấy danh sách đơn hàng của 1 người dùng, món mới nhất xếp trước.
  Future<List<Order>> getOrdersByUser(int userId);

  /// Lấy 1 đơn hàng theo id, trả về null nếu không tìm thấy.
  Future<Order?> getOrderById(int id);

  /// Cập nhật trạng thái của 1 đơn hàng đã tồn tại.
  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus);
}

/// Dữ liệu giả lập cho Đơn hàng, lưu tạm trong bộ nhớ RAM (List).
/// Dùng để dựng UI và test luồng nghiệp vụ trước khi tích hợp SQLite thật.
class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  int _nextId = 1;

  @override
  Future<Order> createOrder(Order order) async {
    // Giả lập độ trễ mạng/database 800ms
    await Future.delayed(const Duration(milliseconds: 800));

    // Giả lập cơ chế Auto Increment ID của Database
    final saved = order.copyWith(id: _nextId++);
    _orders.add(saved);
    return saved;
  }

  @override
  Future<List<Order>> getOrdersByUser(int userId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Lọc đơn theo userId
    final result = _orders.where((o) => o.userId == userId).toList();

    // Sắp xếp đơn mới nhất lên đầu danh sách
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Order?> getOrderById(int id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null; // Không tìm thấy đơn hàng
    }
  }

  @override
  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError("Không tìm thấy đơn hàng có id $orderId");
    }

    // Thay thế object cũ bằng object mới đã được cập nhật trạng thái
    _orders[index] = _orders[index].copyWith(status: newStatus);
  }
}
