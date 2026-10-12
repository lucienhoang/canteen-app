import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';

/// So sánh các lần nhận danh sách đơn để tìm ra đơn nào vừa ĐỔI TRẠNG THÁI.
///
/// Thuần Dart, không phụ thuộc Firebase hay plugin nên test được dễ dàng.
class OrderStatusChangeDetector {
  /// Trạng thái đã biết của từng đơn ở lần nhận trước. null = chưa nhận lần nào.
  Map<String, OrderStatus>? _known;

  /// Nhận danh sách đơn mới nhất, trả về các đơn có trạng thái khác lần trước.
  ///
  /// - Lần nhận ĐẦU TIÊN chỉ ghi nhớ làm mốc, không báo gì (nếu không, mỗi lần mở
  ///   app sẽ bị báo hàng loạt về các đơn cũ).
  /// - Đơn mới xuất hiện sau đó (vừa đặt) không được tính là "đổi trạng thái".
  List<Order> detect(List<Order> orders) {
    final previous = _known;

    final next = <String, OrderStatus>{};
    final changed = <Order>[];
    for (final order in orders) {
      final id = order.id;
      if (id == null) continue;
      next[id] = order.status;

      final before = previous?[id];
      if (before != null && before != order.status) changed.add(order);
    }

    _known = next;
    return changed;
  }
}

/// Theo dõi các đơn của MỘT người dùng và gọi [onStatusChanged] mỗi khi một đơn
/// đổi trạng thái (thường là nhân viên vừa cập nhật ở máy khác).
///
/// Dùng cho phía sinh viên: thông báo hiện ngay trên máy của người đặt đơn,
/// không phải trên máy nhân viên.
class OrderStatusWatcher {
  OrderStatusWatcher({
    required this._orderRepository,
    required this._onStatusChanged,
  });

  final OrderRepository _orderRepository;
  final Future<void> Function(Order order) _onStatusChanged;

  StreamSubscription<List<Order>>? _subscription;

  /// Bắt đầu theo dõi đơn của [userId]. Gọi lại sẽ bắt đầu lại từ đầu (mốc mới).
  void start(String userId) {
    stop();
    final detector = OrderStatusChangeDetector();

    _subscription = _orderRepository
        .watchOrdersByUser(userId)
        .listen(
          (orders) {
            for (final order in detector.detect(orders)) {
              unawaited(_notify(order));
            }
          },
          onError: (Object e, StackTrace st) {
            debugPrint('Theo dõi đơn của người dùng lỗi: $e');
          },
        );
  }

  /// Gửi thông báo là việc phụ: lỗi ở đây không được làm hỏng việc theo dõi.
  Future<void> _notify(Order order) async {
    try {
      await _onStatusChanged(order);
    } catch (e) {
      debugPrint('Gửi thông báo thất bại: $e');
    }
  }

  /// Ngừng theo dõi (khi đăng xuất hoặc đóng màn hình).
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
