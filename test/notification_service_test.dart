import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/core/notifications/notification_service.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';

void main() {
  final sampleItems = [
    const OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 1,
    ),
  ];

  Order buildOrder(OrderStatus status) => Order(
    id: '1',
    userId: 'u1',
    items: sampleItems,
    status: status,
    pickupTime: DateTime(2026, 10, 1, 11, 30),
    createdAt: DateTime(2026, 9, 27, 9, 0),
  );

  test('buildTitle luôn có dạng "Đơn #id"', () {
    final order = buildOrder(OrderStatus.preparing);
    expect(NotificationService.buildTitle(order), 'Đơn #1');
  });

  test('buildBody đúng nội dung cho từng trạng thái', () {
    expect(
      NotificationService.buildBody(buildOrder(OrderStatus.preparing)),
      contains('đang được chuẩn bị'),
    );
    expect(
      NotificationService.buildBody(buildOrder(OrderStatus.ready)),
      contains('sẵn sàng'),
    );
    expect(
      NotificationService.buildBody(buildOrder(OrderStatus.completed)),
      contains('hoàn tất'),
    );
    expect(
      NotificationService.buildBody(buildOrder(OrderStatus.cancelled)),
      contains('huỷ'),
    );
  });
}
