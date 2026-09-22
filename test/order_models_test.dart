import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';

void main() {
  /// Nhóm kiểm thử đơn vị cho Model [OrderItem]
  group('OrderItem', () {
    test('subtotal = priceAtOrder * quantity', () {
      const item = OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      );

      // Kiểm tra thành tiền: 35.000 x 2 = 70.000
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
      expect(updated.menuItemName, 'Cơm sườn'); // giữ nguyên món gốc
      expect(updated.priceAtOrder, 35000); // giữ nguyên giá gốc
    });
  });

  /// Nhóm kiểm thử đơn vị cho Model [Order]
  group('Order', () {
    // Dữ liệu món ăn mẫu dùng chung cho các bài test trong group
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
      // Phép tính: (35.000 * 2) + (5.000 * 1) = 75.000
      expect(order.totalAmount, 75000);
    });

    test('status mặc định là pending khi không truyền vào', () {
      final order = Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );

      // Đơn mới tạo phải mang trạng thái pending
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
      expect(
        updated.totalAmount,
        order.totalAmount,
      ); // Danh sách items không đổi
    });

    test('totalAmount = 0 khi giỏ hàng rỗng', () {
      final order = Order(
        userId: 1,
        items: const [],
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22),
      );

      // Kiểm tra trường hợp danh sách món trống
      expect(order.totalAmount, 0);
    });
  });
}
