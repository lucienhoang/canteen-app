import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/orders/order_tracking_screen.dart';

void main() {
  Future<int> createOrderWithStatus(
    MockOrderRepository repo,
    OrderStatus status,
  ) async {
    final order = await repo.createOrder(
      Order(
        userId: 1,
        items: const [
          OrderItem(
            menuItemId: 1,
            menuItemName: 'Cơm sườn',
            priceAtOrder: 35000,
            quantity: 1,
          ),
        ],
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 25, 9, 0),
      ),
    );
    if (status != OrderStatus.pending) {
      await repo.updateOrderStatus(order.id!, status);
    }
    return order.id!;
  }

  testWidgets('hiện đúng label các bước và đơn #id', (tester) async {
    final repo = MockOrderRepository();
    late int orderId;

    // Dùng runAsync để thoát khỏi "đồng hồ giả" của testWidgets khi gọi
    // Repository có Future.delayed thật — tránh treo vô hạn.
    await tester.runAsync(() async {
      orderId = await createOrderWithStatus(repo, OrderStatus.preparing);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrderTrackingScreen(orderId: orderId, orderRepository: repo),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Đơn #$orderId'), findsOneWidget);
    expect(find.text('Đang xử lý'), findsOneWidget);
    expect(find.text('Đang chuẩn bị'), findsOneWidget);
    expect(find.text('Sẵn sàng lấy'), findsOneWidget);
    expect(find.text('Đã nhận'), findsOneWidget);
  });

  testWidgets('đơn cancelled hiện banner huỷ, không hiện timeline', (
    tester,
  ) async {
    final repo = MockOrderRepository();
    late int orderId;

    await tester.runAsync(() async {
      orderId = await createOrderWithStatus(repo, OrderStatus.cancelled);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OrderTrackingScreen(orderId: orderId, orderRepository: repo),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Đơn hàng đã bị huỷ'), findsOneWidget);
    expect(find.text('Đang xử lý'), findsNothing);
  });

  testWidgets('id không tồn tại thì hiện thông báo lỗi', (tester) async {
    final repo = MockOrderRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: OrderTrackingScreen(orderId: 999, orderRepository: repo),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Không tìm thấy đơn hàng'), findsOneWidget);
  });
}
