import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:canteen_app/data/local/database_helper.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';

void main() {
  late SqliteOrderRepository repository;

  setUpAll(() {
    // Khởi tạo SQLite FFI để giả lập cơ sở dữ liệu khi chạy Unit Test trên máy tính
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Tái tạo lại cơ sở dữ liệu sạch (in-memory) trước mỗi bài test
    await DatabaseHelper.instance.resetForTest();
    repository = SqliteOrderRepository();
  });

  // Dữ liệu mẫu dùng chung cho các test case
  final sampleItems = [
    const OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 2,
    ),
  ];

  test('createOrder lưu Order và trả về id thật từ SQLite', () async {
    final result = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 24, 9, 0),
      ),
    );
    // Kiểm tra ID tự tăng đã được SQLite gán thành công
    expect(result.id, isNotNull);
  });

  test('getOrderById đọc lại đúng Order kèm items từ 2 bảng', () async {
    final created = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        note: 'Ít cay',
        createdAt: DateTime(2026, 9, 24, 9, 0),
      ),
    );

    final found = await repository.getOrderById(created.id!);

    expect(found, isNotNull);
    expect(found!.note, 'Ít cay');
    expect(found.items.length, 1);
    // Tính toán tổng tiền: 35.000 * 2 = 70.000đ
    expect(found.totalAmount, 70000);
  });

  test('getOrdersByUser chỉ trả đơn của đúng user', () async {
    await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 24, 9, 0),
      ),
    );
    await repository.createOrder(
      Order(
        userId: 2,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 12, 0),
        createdAt: DateTime(2026, 9, 24, 9, 5),
      ),
    );

    final orders = await repository.getOrdersByUser(1);

    expect(orders.length, 1);
    expect(orders.first.userId, 1);
  });

  test(
    'updateOrderStatus đổi đúng trạng thái, lưu bền vững qua lần đọc lại',
    () async {
      final created = await repository.createOrder(
        Order(
          userId: 1,
          items: sampleItems,
          pickupTime: DateTime(2026, 10, 1, 11, 30),
          createdAt: DateTime(2026, 9, 24, 9, 0),
        ),
      );

      await repository.updateOrderStatus(created.id!, OrderStatus.preparing);
      final updated = await repository.getOrderById(created.id!);

      expect(updated?.status, OrderStatus.preparing);
    },
  );

  test('updateOrderStatus ném lỗi khi id không tồn tại', () async {
    expect(
      () => repository.updateOrderStatus(999, OrderStatus.preparing),
      throwsStateError,
    );
  });
}
