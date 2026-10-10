import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/staff/staff_screen.dart';

void main() {
  Order buildOrder({String userName = '', String userMssv = ''}) => Order(
    userId: 'u1',
    userName: userName,
    userMssv: userMssv,
    items: const [
      OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      ),
    ],
    pickupTime: DateTime(2026, 10, 12, 11, 30),
    createdAt: DateTime(2026, 10, 10, 9, 0),
  );

  /// MockOrderRepository có Future.delayed thật, nên phải bọc trong runAsync
  /// trước khi dựng widget (testWidgets dùng "đồng hồ giả" sẽ treo nếu không).
  Future<MockOrderRepository> repoWith(
    WidgetTester tester,
    List<Order> orders,
  ) async {
    final repo = MockOrderRepository();
    await tester.runAsync(() async {
      for (final order in orders) {
        await repo.createOrder(order);
      }
    });
    return repo;
  }

  Future<void> pumpStaff(WidgetTester tester, MockOrderRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(home: StaffScreen(orderRepository: repo)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('chưa có đơn nào thì hiện thông báo trống', (tester) async {
    final repo = await repoWith(tester, []);
    await pumpStaff(tester, repo);

    expect(find.textContaining('có đơn nào cần xử lý'), findsOneWidget);
  });

  testWidgets('thẻ đơn hiện tên và MSSV của người đặt', (tester) async {
    final repo = await repoWith(tester, [
      buildOrder(userName: 'Nguyễn Văn A', userMssv: '2110001'),
    ]);
    await pumpStaff(tester, repo);

    expect(find.text('Đơn #1'), findsOneWidget);
    expect(find.text('Nguyễn Văn A · 2110001'), findsOneWidget);
    expect(find.text('Cơm sườn x 2'), findsOneWidget);
  });

  testWidgets('đơn cũ không có tên thì không hiện dòng tên', (tester) async {
    final repo = await repoWith(tester, [buildOrder()]);
    await pumpStaff(tester, repo);

    expect(find.text('Đơn #1'), findsOneWidget);
    expect(find.textContaining(' · '), findsNothing);
  });

  testWidgets('đơn đã hủy không nằm trong danh sách đang xử lý', (
    tester,
  ) async {
    final repo = await repoWith(tester, [buildOrder(userName: 'A')]);
    await tester.runAsync(
      () => repo.updateOrderStatus('1', OrderStatus.cancelled),
    );
    await pumpStaff(tester, repo);

    expect(find.text('Đơn #1'), findsNothing);
  });

  testWidgets('bấm chuyển trạng thái thì thẻ tự cập nhật qua stream', (
    tester,
  ) async {
    final repo = await repoWith(tester, [buildOrder(userName: 'A')]);
    await pumpStaff(tester, repo);

    // Lúc đầu chip trạng thái là "Đang xử lý"
    expect(find.text('Đang xử lý'), findsOneWidget);

    await tester.tap(find.text('Chuyển: Đang chuẩn bị'));
    await tester.pump(); // bắt đầu cập nhật
    await tester.pump(
      const Duration(milliseconds: 900),
    ); // qua độ trễ 800ms của Mock
    await tester.pumpAndSettle();

    // Chip đổi sang "Đang chuẩn bị" mà không cần tải lại thủ công
    expect(find.text('Đang chuẩn bị'), findsOneWidget);
    expect(find.text('Đang xử lý'), findsNothing);
  });
}
