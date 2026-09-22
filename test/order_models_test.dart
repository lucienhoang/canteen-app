import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';

void main() {
  group('OrderItem', () {
    test('subtotal = priceAtOrder * quantity', () {
      const item = OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      );
      expect(item.subtotal, 70000);
    });

    test('copyWith chỉ thay field được truyền vào', () {
      const item = OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      );
      final updated = item.copyWith(quantity: 3);

      expect(updated.quantity, 3);
      expect(updated.menuItemName, 'Cơm sườn'); // giữ nguyên
      expect(updated.priceAtOrder, 35000); // giữ nguyên
    });
  });

  group('Order', () {
    final sampleItems = [
      const OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      ),
      const OrderItem(
        menuItemId: 2,
        menuItemName: 'Trà đá',
        priceAtOrder: 5000,
        quantity: 1,
      ),
    ];

    test('totalAmount cộng dồn đúng từ nhiều OrderItem', () {
      final order = Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );
      // (35000*2) + (5000*1) = 75000
      expect(order.totalAmount, 75000);
    });

    test('status mặc định là pending khi không truyền vào', () {
      final order = Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );
      expect(order.status, OrderStatus.pending);
    });

    test('copyWith đổi status mà không ảnh hưởng field khác', () {
      final order = Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );
      final updated = order.copyWith(status: OrderStatus.preparing);

      expect(updated.status, OrderStatus.preparing);
      expect(updated.totalAmount, order.totalAmount); // items không đổi
    });

    test('totalAmount = 0 khi giỏ hàng rỗng', () {
      final order = Order(
        userId: 1,
        items: const [],
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );
      expect(order.totalAmount, 0);
    });
  });
}
