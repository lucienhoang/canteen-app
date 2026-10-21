import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';

class MyOrdersViewModel extends ChangeNotifier {
  MyOrdersViewModel({
    required this.userId,
    required this.orderRepository,
  }) {
    _initStream();
  }

  final String userId;
  final OrderRepository orderRepository;

  List<Order> _activeOrders = [];
  List<Order> get activeOrders => _activeOrders;

  StreamSubscription<List<Order>>? _subscription;

  void _initStream() {
    _subscription = orderRepository.watchOrdersByUser(userId).listen((orders) {
      // 1. Lọc đơn đang xử lý (bỏ qua completed và cancelled)
      final filtered = orders.where((order) {
        return order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled;
      }).toList();

      // 2. Sắp xếp mới nhất ở trên (createdAt giảm dần)
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _activeOrders = filtered;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // Hủy subscription khi widget bị hủy để tránh rò rỉ bộ nhớ
    _subscription?.cancel();
    super.dispose();
  }
}