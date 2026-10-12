import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/auth_repository.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/auth/auth_viewmodel.dart';
import 'package:canteen_app/features/orders/order_notification_host.dart';
import 'package:canteen_app/features/orders/order_status_watcher.dart';

/// Nhường một nhịp để các sự kiện bất đồng bộ của stream kịp chạy.
Future<void> settle() => Future<void>.delayed(Duration.zero);

Order buildOrder(String userId, {String? id, OrderStatus? status}) => Order(
  id: id,
  userId: userId,
  items: const [
    OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 1,
    ),
  ],
  status: status ?? OrderStatus.pending,
  pickupTime: DateTime(2026, 10, 14, 11, 30),
  createdAt: DateTime(2026, 10, 12, 9, 0),
);

void main() {
  group('OrderStatusChangeDetector', () {
    test('lần nhận đầu tiên chỉ làm mốc, không báo gì', () {
      final detector = OrderStatusChangeDetector();
      final changed = detector.detect([
        buildOrder('u1', id: '1', status: OrderStatus.preparing),
        buildOrder('u1', id: '2', status: OrderStatus.ready),
      ]);
      expect(changed, isEmpty);
    });

    test('báo đơn có trạng thái khác lần trước', () {
      final detector = OrderStatusChangeDetector()
        ..detect([buildOrder('u1', id: '1')]);

      final changed = detector.detect([
        buildOrder('u1', id: '1', status: OrderStatus.preparing),
      ]);

      expect(changed.length, 1);
      expect(changed.first.id, '1');
      expect(changed.first.status, OrderStatus.preparing);
    });

    test('không đổi gì thì không báo', () {
      final detector = OrderStatusChangeDetector()
        ..detect([buildOrder('u1', id: '1')]);
      expect(detector.detect([buildOrder('u1', id: '1')]), isEmpty);
    });

    test('đơn mới xuất hiện sau mốc không bị tính là đổi trạng thái', () {
      final detector = OrderStatusChangeDetector()
        ..detect([buildOrder('u1', id: '1')]);

      final changed = detector.detect([
        buildOrder('u1', id: '1'),
        buildOrder('u1', id: '2'),
      ]);
      expect(changed, isEmpty);
    });

    test('nhiều đơn đổi cùng lúc thì báo hết, đơn không đổi thì bỏ qua', () {
      final detector = OrderStatusChangeDetector()
        ..detect([
          buildOrder('u1', id: '1'),
          buildOrder('u1', id: '2'),
          buildOrder('u1', id: '3'),
        ]);

      final changed = detector.detect([
        buildOrder('u1', id: '1', status: OrderStatus.preparing),
        buildOrder('u1', id: '2'),
        buildOrder('u1', id: '3', status: OrderStatus.cancelled),
      ]);

      expect(changed.map((o) => o.id), ['1', '3']);
    });

    test('đơn biến mất khỏi danh sách thì không gây lỗi', () {
      final detector = OrderStatusChangeDetector()
        ..detect([buildOrder('u1', id: '1'), buildOrder('u1', id: '2')]);
      expect(detector.detect([buildOrder('u1', id: '1')]), isEmpty);
    });
  });

  group('OrderStatusWatcher', () {
    test('báo khi đơn của người dùng đổi trạng thái', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(buildOrder('u1'));
      final notified = <Order>[];
      final watcher = OrderStatusWatcher(
        orderRepository: repo,
        onStatusChanged: (order) async => notified.add(order),
      )..start('u1');

      await settle();
      expect(notified, isEmpty); // lần đầu chỉ là mốc

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();

      expect(notified.length, 1);
      expect(notified.first.status, OrderStatus.preparing);
      watcher.stop();
    });

    test('báo từng bước khi đơn đổi trạng thái nhiều lần', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(buildOrder('u1'));
      final statuses = <OrderStatus>[];
      final watcher = OrderStatusWatcher(
        orderRepository: repo,
        onStatusChanged: (order) async => statuses.add(order.status),
      )..start('u1');
      await settle();

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();
      await repo.updateOrderStatus(saved.id!, OrderStatus.ready);
      await settle();

      expect(statuses, [OrderStatus.preparing, OrderStatus.ready]);
      watcher.stop();
    });

    test('đơn của người khác không gây thông báo', () async {
      final repo = MockOrderRepository();
      final mine = await repo.createOrder(buildOrder('u1'));
      final others = await repo.createOrder(buildOrder('u2'));
      final notified = <Order>[];
      final watcher = OrderStatusWatcher(
        orderRepository: repo,
        onStatusChanged: (order) async => notified.add(order),
      )..start('u1');
      await settle();

      await repo.updateOrderStatus(others.id!, OrderStatus.preparing);
      await settle();
      expect(notified, isEmpty);

      await repo.updateOrderStatus(mine.id!, OrderStatus.preparing);
      await settle();
      expect(notified.length, 1);
      watcher.stop();
    });

    test('sau stop thì không báo nữa', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(buildOrder('u1'));
      final notified = <Order>[];
      final watcher = OrderStatusWatcher(
        orderRepository: repo,
        onStatusChanged: (order) async => notified.add(order),
      )..start('u1');
      await settle();

      watcher.stop();
      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();

      expect(notified, isEmpty);
    });

    test('gửi thông báo lỗi không làm hỏng việc theo dõi', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(buildOrder('u1'));
      var calls = 0;
      final watcher = OrderStatusWatcher(
        orderRepository: repo,
        onStatusChanged: (order) async {
          calls++;
          throw Exception('plugin lỗi');
        },
      )..start('u1');
      await settle();

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();
      await repo.updateOrderStatus(saved.id!, OrderStatus.ready);
      await settle();

      expect(calls, 2); // lần lỗi đầu không làm mất lần sau
      watcher.stop();
    });
  });

  group('MockOrderRepository.watchOrdersByUser', () {
    test('chỉ phát đơn của đúng người dùng', () async {
      final repo = MockOrderRepository();
      await repo.createOrder(buildOrder('u1'));
      await repo.createOrder(buildOrder('u2'));
      final counts = <int>[];
      final sub = repo
          .watchOrdersByUser('u1')
          .listen((o) => counts.add(o.length));
      await settle();

      expect(counts, [1]);
      await sub.cancel();
    });
  });

  group('OrderNotificationHost', () {
    testWidgets('theo dõi khi sinh viên đăng nhập và dừng khi bị gỡ', (
      tester,
    ) async {
      final repo = MockOrderRepository();
      final auth = AuthViewModel(MockAuthRepository());
      await auth.signIn('2110001', '123456'); // id người dùng là 'student-1'

      final saved = await tester.runAsync(
        () => repo.createOrder(buildOrder('student-1')),
      );
      final notified = <Order>[];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<OrderRepository>.value(value: repo),
            ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          ],
          child: MaterialApp(
            home: OrderNotificationHost(
              onStatusChanged: (order) async => notified.add(order),
              child: const Text('MENU'),
            ),
          ),
        ),
      );
      expect(find.text('MENU'), findsOneWidget);

      // Nhận mốc đầu tiên (xả microtask của zone giả)
      await tester.pump();

      // Nhân viên đổi trạng thái
      await tester.runAsync(
        () => repo.updateOrderStatus(saved!.id!, OrderStatus.preparing),
      );
      await tester.pump(); // giao snapshot mới cho watcher
      await tester.pump(); // chạy tiếp _notify -> onStatusChanged
      expect(notified.length, 1);

      // Gỡ widget (như khi đăng xuất): dispose -> watcher.stop()
      await tester.pumpWidget(const MaterialApp(home: Text('LOGIN')));
      await tester.runAsync(
        () => repo.updateOrderStatus(saved!.id!, OrderStatus.ready),
      );
      await tester.pump();
      expect(notified.length, 1);
    });
  });
}
