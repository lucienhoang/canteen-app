import 'dart:async';

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
  Future<List<Order>> getOrdersByUser(String userId);

  /// Lấy 1 đơn hàng theo id, trả về null nếu không tìm thấy.
  Future<Order?> getOrderById(String id);

  /// Cập nhật trạng thái của 1 đơn hàng đã tồn tại.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus);

  /// Lấy toàn bộ đơn hàng trong hệ thống, mới nhất trước (dùng cho màn hình nhân viên).
  Future<List<Order>> getAllOrders();

  /// Theo dõi toàn bộ đơn hàng: phát danh sách hiện tại ngay khi bắt đầu nghe,
  /// rồi phát lại danh sách mới mỗi khi có đơn được tạo hoặc đổi trạng thái.
  Stream<List<Order>> watchAllOrders();

  /// Theo dõi 1 đơn hàng: phát đơn hiện tại ngay khi bắt đầu nghe,
  /// rồi phát lại mỗi khi nó thay đổi. Phát null nếu không tìm thấy đơn.
  Stream<Order?> watchOrder(String id);
}

/// Dựng một stream "phát lại kết quả [query] mỗi khi [changes] có tín hiệu".
///
/// - Đăng ký nghe [changes] TRƯỚC rồi mới chạy query đầu tiên, để không bỏ sót
///   thay đổi xảy ra giữa chừng.
/// - Hủy nghe thì ngừng đăng ký [changes], không để rò rỉ.
/// - Query lỗi thì phát lỗi vào stream (không làm sập app), lần thay đổi sau vẫn thử lại.
Stream<T> _watchChanges<T>({
  required Stream<void> changes,
  required Future<T> Function() query,
}) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;

  Future<void> emit() async {
    try {
      final value = await query();
      if (controller.hasListener) controller.add(value);
    } catch (e, st) {
      if (controller.hasListener) controller.addError(e, st);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = changes.listen((_) => emit());
      emit();
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}

/// Dữ liệu giả lập cho Đơn hàng, lưu tạm trong bộ nhớ RAM (List).
/// Dùng để dựng UI và test luồng nghiệp vụ trước khi tích hợp SQLite thật.
class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  int _nextId = 1;

  /// Phát tín hiệu mỗi khi dữ liệu đơn hàng thay đổi.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Order> _sortedSnapshot() {
    final result = List<Order>.of(_orders);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Order? _findById(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<Order> createOrder(Order order) async {
    // Giả lập độ trễ mạng/database 800ms
    await Future.delayed(const Duration(milliseconds: 800));

    // Giả lập cơ chế Auto Increment ID của Database (id dạng chuỗi)
    final saved = order.copyWith(id: '${_nextId++}');
    _orders.add(saved);
    _changes.add(null);
    return saved;
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Lọc đơn theo userId
    final result = _orders.where((o) => o.userId == userId).toList();

    // Sắp xếp đơn mới nhất lên đầu danh sách
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Order?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _findById(id); // null nếu không tìm thấy đơn hàng
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw StateError("Không tìm thấy đơn hàng có id $orderId");
    }

    // Thay thế object cũ bằng object mới đã được cập nhật trạng thái
    _orders[index] = _orders[index].copyWith(status: newStatus);
    _changes.add(null);
  }

  @override
  Future<List<Order>> getAllOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _sortedSnapshot();
  }

  // Các hàm watch đọc thẳng từ RAM, không giả lập độ trễ.
  @override
  Stream<List<Order>> watchAllOrders() => _watchChanges(
    changes: _changes.stream,
    query: () async => _sortedSnapshot(),
  );

  @override
  Stream<Order?> watchOrder(String id) =>
      _watchChanges(changes: _changes.stream, query: () async => _findById(id));
}

/// Triển khai [OrderRepository] sử dụng cơ sở dữ liệu SQLite dưới máy.
///
/// Bảng `orders` vẫn dùng khóa số tự tăng. Ra ngoài repository thì id luôn là
/// chuỗi ([Order.id]); trong repository đổi qua lại bằng `toString()` / `int.tryParse`.
class SqliteOrderRepository implements OrderRepository {
  /// Khởi tạo repository với [DatabaseHelper].
  /// Mặc định dùng [DatabaseHelper.instance] nếu không truyền vào.
  SqliteOrderRepository({DatabaseHelper? databaseHelper})
    : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  /// Tín hiệu "dữ liệu đơn hàng vừa thay đổi", dùng CHUNG cho mọi đối tượng
  /// [SqliteOrderRepository] (static). Cần vậy vì app tạo nhiều đối tượng
  /// repository (giỏ hàng, màn nhân viên, màn theo dõi...) cùng ghi vào một
  /// database: ghi qua đối tượng này thì người nghe ở đối tượng kia cũng phải biết.
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  @override
  Future<Order> createOrder(Order order) async {
    final db = await _dbHelper.database;

    // Sử dụng Transaction để đảm bảo tính toàn vẹn dữ liệu giữa bảng orders và order_items
    final saved = await db.transaction<Order>((txn) async {
      // 1. Thêm thông tin chung của đơn hàng vào bảng orders
      final orderId = await txn.insert('orders', {
        'user_id': order.userId,
        'user_name': order.userName,
        'user_mssv': order.userMssv,
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
      // 3. Trả về đối tượng Order mới đã được gắn ID tự tăng từ SQLite (dạng chuỗi)
      return order.copyWith(id: orderId.toString());
    });

    // Báo cho người đang theo dõi SAU khi transaction đã ghi xong
    _changes.add(null);
    return saved;
  }

  @override
  Future<List<Order>> getOrdersByUser(String userID) async {
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
  Future<Order?> getOrderById(String id) async {
    // Id không phải số thì chắc chắn không có trong bảng
    final rowId = int.tryParse(id);
    if (rowId == null) return null;

    final db = await _dbHelper.database;
    final orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [rowId],
    );

    if (orderMaps.isEmpty) return null;

    final items = await _getItemsForOrder(db, rowId);
    return Order.fromMap(orderMaps.first, items);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final rowId = int.tryParse(orderId);
    if (rowId == null) {
      throw StateError('Không tìm thấy đơn hàng có id $orderId');
    }

    final db = await _dbHelper.database;
    final count = await db.update(
      'orders',
      {'status': newStatus.name},
      where: 'id = ?',
      whereArgs: [rowId],
    );
    if (count == 0) {
      throw StateError('Không tìm thấy đơn hàng có id $orderId');
    }

    _changes.add(null);
  }

  /// Hàm phụ trợ lấy danh sách OrderItem theo orderId (khóa số của SQLite)
  Future<List<OrderItem>> _getItemsForOrder(Database db, int orderId) async {
    final itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return itemMaps.map(OrderItem.fromMap).toList();
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final db = await _dbHelper.database;
    final orderMaps = await db.query('orders', orderBy: 'created_at DESC');

    final orders = <Order>[];
    for (final map in orderMaps) {
      final items = await _getItemsForOrder(db, map['id'] as int);
      orders.add(Order.fromMap(map, items));
    }
    return orders;
  }

  @override
  Stream<List<Order>> watchAllOrders() =>
      _watchChanges(changes: _changes.stream, query: getAllOrders);

  @override
  Stream<Order?> watchOrder(String id) =>
      _watchChanges(changes: _changes.stream, query: () => getOrderById(id));
}
