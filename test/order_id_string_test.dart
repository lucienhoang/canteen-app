import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/core/notifications/notification_service.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';

void main() {
  final sampleOrder = Order(
    userId: 'u1',
    items: const [
      OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 1,
      ),
    ],
    pickupTime: DateTime(2026, 10, 12, 11, 30),
    createdAt: DateTime(2026, 10, 10, 9, 0),
  );

  group('Order.fromMap', () {
    test('id số của SQLite được đổi thành chuỗi', () {
      final order = Order.fromMap({
        'id': 5,
        'user_id': 'u1',
        'status': 'pending',
        'pickup_time': DateTime(2026, 10, 12).toIso8601String(),
        'note': null,
        'created_at': DateTime(2026, 10, 10).toIso8601String(),
      }, const []);
      expect(order.id, '5');
    });

    test('thiếu id thì id là null', () {
      final order = Order.fromMap({
        'user_id': 'u1',
        'status': 'pending',
        'pickup_time': DateTime(2026, 10, 12).toIso8601String(),
        'created_at': DateTime(2026, 10, 10).toIso8601String(),
      }, const []);
      expect(order.id, isNull);
    });
  });

  group('MockOrderRepository với id chuỗi', () {
    test('createOrder gán id chuỗi tăng dần', () async {
      final repo = MockOrderRepository();
      final a = await repo.createOrder(sampleOrder);
      final b = await repo.createOrder(sampleOrder);
      expect(a.id, '1');
      expect(b.id, '2');
    });

    test('getOrderById tìm đúng đơn, id lạ trả về null', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      expect((await repo.getOrderById(saved.id!))?.id, saved.id);
      expect(await repo.getOrderById('khong-co'), isNull);
    });

    test('updateOrderStatus đổi trạng thái, id lạ ném StateError', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      expect(
        (await repo.getOrderById(saved.id!))?.status,
        OrderStatus.preparing,
      );
      expect(
        repo.updateOrderStatus('khong-co', OrderStatus.preparing),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('NotificationService.notificationIdFor', () {
    test('cùng id đơn luôn ra cùng một số', () {
      expect(
        NotificationService.notificationIdFor('abc123'),
        NotificationService.notificationIdFor('abc123'),
      );
    });

    test('hai id khác nhau ra hai số khác nhau', () {
      expect(
        NotificationService.notificationIdFor('1'),
        isNot(NotificationService.notificationIdFor('2')),
      );
    });

    test('luôn là số không âm và vừa số nguyên 32-bit', () {
      for (final id in ['1', '999999', 'k3Zq9XwLm0PaBcDeFgHiJkLmNoPq']) {
        final n = NotificationService.notificationIdFor(id);
        expect(n, greaterThanOrEqualTo(0));
        expect(n, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });
}
