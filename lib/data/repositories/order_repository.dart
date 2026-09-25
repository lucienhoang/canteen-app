import 'package:canteen_app/data/local/database_helper.dart';
import 'package:sqflite/sqlite_api.dart';

import '../models/order.dart';
import '../models/order_status.dart';
import '../models/order_item.dart';

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

/// Triển khai [OrderRepository] sử dụng cơ sở dữ liệu SQLite dưới máy.
class SqliteOrderRepository implements OrderRepository {
  /// Khởi tạo repository với [DatabaseHelper].
  /// Mặc định dùng [DatabaseHelper.instance] nếu không truyền vào.
  SqliteOrderRepository({DatabaseHelper? databaseHelper})
    : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  @override
  Future<Order> createOrder(Order order) async {
    final db = await _dbHelper.database;

    // Sử dụng Transaction để đảm bảo tính toàn vẹn dữ liệu giữa bảng orders và order_items
    return db.transaction<Order>((txn) async {
      // 1. Thêm thông tin chung của đơn hàng vào bảng orders
      final orderId = await txn.insert('orders', {
        'user_id': order.userId,
        'status': order.status.name,
        'pickup_time': order.pickupTime.toIso8601String(),
        'note': order.note,
        'created_at': order.createdAt.toIso8601String(),
      });

      // 2. Thêm danh sách chi tiết các món ăn vào bảng order_items
      for (final item in order.items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'menu_item_id': item.menuItemId,
          'menu_item_name': item.menuItemName,
          'price_at_order': item.priceAtOrder,
          'quantity': item.quantity,
        });
      }
      // 3. Trả về đối tượng Order mới đã được gắn ID tự tăng từ SQLite
      return order.copyWith(id: orderId);
    });
  }

  @override
  Future<List<Order>> getOrdersByUser(int userID) async {
    final db = await _dbHelper.database;
    final orderMaps = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userID],
      orderBy: 'created_at DESC', // Sắp xếp đơn hàng mới nhất lên đầu
    );

    final orders = <Order>[];
    for (final map in orderMaps) {
      final items = await _getItemsForOrder(db, map['id'] as int);
      orders.add(Order.fromMap(map, items));
    }
    return orders;
  }

  @override
  Future<Order?> getOrderById(int id) async {
    final db = await _dbHelper.database;
    final orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (orderMaps.isEmpty) return null;

    final items = await _getItemsForOrder(db, id);
    return Order.fromMap(orderMaps.first, items);
  }

  @override
  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    final db = await _dbHelper.database;
    final count = await db.update(
      'orders',
      {'status': newStatus.name},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (count == 0) {
      throw StateError('Không tìm thấy đơn hàng có id $orderId');
    }
  }

  /// Hàm phụ trợ lấy danh sách OrderItem theo orderId
  Future<List<OrderItem>> _getItemsForOrder(Database db, int orderId) async {
    final itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return itemMaps.map(OrderItem.fromMap).toList();
  }
}
