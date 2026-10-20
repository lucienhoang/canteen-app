import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/auth_repository.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/auth/auth_viewmodel.dart';
import 'package:canteen_app/features/orders/my_orders_button.dart';

// --- TẠO MOCK REPOSITORY ---
// Dùng lại ý tưởng từ Unit test để điều khiển luồng Stream
class MockStreamOrderRepository implements OrderRepository {
  final StreamController<List<Order>> controller = StreamController<List<Order>>.broadcast();

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) => controller.stream;

  @override
  Future<Order> createOrder(Order order) async => order;

  @override
  Future<Order?> getOrderById(String id) async => null;

  @override
  Stream<Order?> watchOrder(String id) => const Stream.empty();

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}

  @override
  Future<List<Order>> getAllOrders() {
    // TODO: implement getAllOrders
    throw UnimplementedError();
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) {
    // TODO: implement getOrdersByUser
    throw UnimplementedError();
  }

  @override
  Stream<List<Order>> watchAllOrders() {
    // TODO: implement watchAllOrders
    throw UnimplementedError();
  }
}

void main() {
  // Hàm tạo Order giả
  Order createOrder({required String id, required OrderStatus status}) {
    return Order(
      id: id,
      userId: '2110001',
      userName: 'Sinh Vien',
      userMssv: '2110001',
      items: [],
      pickupTime: DateTime.now(),
      status: status,
      createdAt: DateTime.now(),
    );
  }

  // Hàm setup môi trường UI
  Future<void> pumpButton(WidgetTester tester, OrderRepository repo) async {
    final auth = AuthViewModel(MockAuthRepository());
    await auth.signIn('2110001', '123456'); // Giả lập đã đăng nhập

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          Provider<OrderRepository>.value(value: repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MyOrdersButton(),
          ),
        ),
      ),
    );
  }

  testWidgets('Badge hiển thị đúng số lượng đơn đang xử lý', (tester) async {
    final repo = MockStreamOrderRepository();
    await pumpButton(tester, repo);

    // Bơm 3 đơn: 2 đang xử lý (pending, preparing), 1 đã xong (completed)
    repo.controller.add([
      createOrder(id: '1', status: OrderStatus.pending),
      createOrder(id: '2', status: OrderStatus.preparing),
      createOrder(id: '3', status: OrderStatus.completed),
    ]);

    await tester.pumpAndSettle();

    // Vì chỉ có 2 đơn đang xử lý nên Badge phải hiện số '2'
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing); // Không được hiện tổng 3

    // Test: Cập nhật luồng về 0 đơn (đã nhận hết)
    repo.controller.add([]);
    await tester.pumpAndSettle();

    // Badge sẽ ẩn, số 2 biến mất
    expect(find.text('2'), findsNothing);
  });
}