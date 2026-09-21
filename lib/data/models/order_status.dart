enum OrderStatus { pending, preparing, ready, completed, cancelled }

extension OrderStatusX on OrderStatus {
  static const _transitions = {
    OrderStatus.pending: [OrderStatus.preparing, OrderStatus.cancelled],
    OrderStatus.preparing: [OrderStatus.ready, OrderStatus.cancelled],
    OrderStatus.ready: [OrderStatus.completed],
    OrderStatus.completed: <OrderStatus>[],
    OrderStatus.cancelled: <OrderStatus>[],
  };

  bool canChangeTo(OrderStatus next) => _transitions[this]!.contains(next);

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Đang xử lý';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.ready:
        return 'Sẵn sàng lấy';
      case OrderStatus.completed:
        return 'Đã nhận';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
