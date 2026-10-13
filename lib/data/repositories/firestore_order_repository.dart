import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';
import 'order_repository.dart';
import 'order_repository_exception.dart';

/// Lưu đơn hàng trên Firestore: collection `orders`, mỗi đơn là một document,
/// các món nằm ngay trong document (mảng `items`).
///
/// Quyết định quan trọng:
/// - Tạo đơn và đổi trạng thái dùng TRANSACTION. Transaction không xếp hàng khi
///   mất mạng mà báo lỗi ngay, nên không có chuyện "báo thất bại rồi sau đó đơn
///   tự gửi đi lúc có mạng" làm sinh đơn trùng khi người dùng bấm lại.
/// - Mọi thao tác ghi/đọc một lần đều có timeout, app không bao giờ treo vô hạn.
/// - Lỗi của Firebase được dịch thành [OrderRepositoryException] có thông báo
///   tiếng Việt, ViewModel không cần biết gì về Firebase.
class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _collection = 'orders';
  static const _timeout = Duration(seconds: 10);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(_collection);

  // ---------------------------------------------------------------------------
  // Chuyển đổi dữ liệu (thuần Dart, test được mà không cần Firebase)
  // ---------------------------------------------------------------------------

  /// Đổi [Order] thành dữ liệu lưu vào document. Không chứa id (id là tên document).
  @visibleForTesting
  static Map<String, dynamic> orderToData(Order order) {
    return {
      'userId': order.userId,
      'userName': order.userName,
      'userMssv': order.userMssv,
      'status': order.status.name,
      'pickupTime': Timestamp.fromDate(order.pickupTime),
      'note': order.note,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'items': [
        for (final item in order.items)
          {
            'menuItemId': item.menuItemId,
            'menuItemName': item.menuItemName,
            'priceAtOrder': item.priceAtOrder,
            'quantity': item.quantity,
          },
      ],
      // Dư thừa có chủ ý: tiện xem trên Console và làm thống kê doanh thu sau này.
      'totalAmount': order.totalAmount,
    };
  }

  /// Đọc dữ liệu document thành [Order]. Dữ liệu thiếu thì dùng giá trị an toàn.
  @visibleForTesting
  static Order orderFromData(String id, Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final items = rawItems.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return OrderItem(
        menuItemId: (map['menuItemId'] as num).toInt(),
        menuItemName: map['menuItemName'] as String,
        priceAtOrder: (map['priceAtOrder'] as num).toInt(),
        quantity: (map['quantity'] as num).toInt(),
      );
    }).toList();

    return Order(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userMssv: data['userMssv'] as String? ?? '',
      items: items,
      status: _parseStatus(data['status']),
      pickupTime: _toDate(data['pickupTime']),
      note: data['note'] as String?,
      createdAt: _toDate(data['createdAt']),
    );
  }

  static OrderStatus _parseStatus(Object? raw) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => OrderStatus.pending,
    );
  }

  static DateTime _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ---------------------------------------------------------------------------
  // Xử lý lỗi
  // ---------------------------------------------------------------------------

  /// Đổi mã lỗi của Firebase thành thông báo thân thiện.
  @visibleForTesting
  static String messageForCode(String code) {
    switch (code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Không có kết nối mạng, kiểm tra rồi thử lại nhé';
      case 'permission-denied':
        return 'Bạn không có quyền thực hiện thao tác này';
      case 'unauthenticated':
        return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
      default:
        return 'Có lỗi xảy ra, thử lại nhé';
    }
  }

  static OrderRepositoryException _mapError(Object error) {
    if (error is OrderRepositoryException) return error;
    if (error is TimeoutException) {
      return OrderRepositoryException(messageForCode('unavailable'));
    }
    if (error is FirebaseException) {
      return OrderRepositoryException(messageForCode(error.code));
    }
    return OrderRepositoryException(messageForCode(''));
  }

  /// Chạy một thao tác với timeout, và dịch mọi lỗi thành [OrderRepositoryException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } catch (e, st) {
      debugPrint('Firestore lỗi: $e');
      Error.throwWithStackTrace(_mapError(e), st);
    }
  }

  // ---------------------------------------------------------------------------
  // Hợp đồng OrderRepository
  // ---------------------------------------------------------------------------

  @override
  Future<Order> createOrder(Order order) {
    return _guard(() async {
      final doc = _orders.doc(); // id ngẫu nhiên sinh ngay trên máy
      final saved = order.copyWith(id: doc.id);
      await _firestore.runTransaction((transaction) async {
        transaction.set(doc, orderToData(saved));
      }, timeout: _timeout);
      return saved;
    });
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) {
    return _guard(() async {
      // Chỉ lọc theo userId rồi sắp xếp trong app: kết hợp where + orderBy
      // sẽ đòi tạo composite index trên Firebase Console.
      final snapshot = await _orders.where('userId', isEqualTo: userId).get();
      final orders = snapshot.docs
          .map((doc) => orderFromData(doc.id, doc.data()))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  @override
  Future<Order?> getOrderById(String id) {
    return _guard(() async {
      final snapshot = await _orders.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return orderFromData(snapshot.id, data);
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    return _guard(() async {
      await _firestore.runTransaction((transaction) async {
        final ref = _orders.doc(orderId);
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw const OrderRepositoryException('Không tìm thấy đơn hàng');
        }

        // Kiểm tra lại trên dữ liệu mới nhất: người khác có thể vừa đổi trạng thái
        final current = _parseStatus(snapshot.data()?['status']);
        if (!current.canChangeTo(newStatus)) {
          throw const OrderRepositoryException(
            'Trạng thái đơn đã thay đổi, danh sách vừa được làm mới',
          );
        }

        transaction.update(ref, {'status': newStatus.name});
      }, timeout: _timeout);
    });
  }

  @override
  Future<List<Order>> getAllOrders() {
    return _guard(() async {
      final snapshot = await _orders
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => orderFromData(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Stream<List<Order>> watchAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => orderFromData(doc.id, doc.data()))
              .toList(),
        )
        .transform(_errorMapper<List<Order>>());
  }

  @override
  Stream<Order?> watchOrder(String id) {
    return _orders
        .doc(id)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;
          return orderFromData(snapshot.id, data);
        })
        .transform(_errorMapper<Order?>());
  }

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => orderFromData(doc.id, doc.data()))
              .toList();
          // Sắp xếp trong app để không phải tạo composite index
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        })
        .transform(_errorMapper<List<Order>>());
  }

  /// Biến lỗi của stream thành [OrderRepositoryException] để ViewModel hiện đúng thông báo.
  StreamTransformer<T, T> _errorMapper<T>() {
    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) {
        debugPrint('Firestore stream lỗi: $error');
        sink.addError(_mapError(error), stackTrace);
      },
    );
  }
}
