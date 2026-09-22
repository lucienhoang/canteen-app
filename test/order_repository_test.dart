import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';

void main() {
  late MockOrderRepository repository;

  // Khởi tạo lại repository mới trước mỗi bài test để đảm bảo dữ liệu sạch
  setUp(() {
    repository = MockOrderRepository();
  });

  // Dữ liệu dòng món ăn mẫu dùng cho kiểm thử
  final sampleItems = [
    const OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 1,
    ),
  ];

  test('createOrder gán id tự tăng dần', () async {
    final order1 = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22, 9, 0),
      ),
    );
    final order2 = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 12, 0),
        createdAt: DateTime(2026, 9, 22, 9, 5),
      ),
    );

    // Kiểm tra ID được sinh tự động tăng dần
    expect(order1.id, 1);
    expect(order2.id, 2);
  });

  test('getOrdersByUser chỉ trả đơn của đúng user, mới nhất trước', () async {
    await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22, 9, 0),
      ),
    );
    await repository.createOrder(
      Order(
        userId: 2, // User khác (không được bao gồm trong kết quả)
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 12, 0),
        createdAt: DateTime(2026, 9, 22, 9, 5),
      ),
    );
    await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 13, 0),
        createdAt: DateTime(
          2026,
          9,
          22,
          10,
          0,
        ), // Đơn tạo sau -> phải nằm ở đầu
      ),
    );

    final orders = await repository.getOrdersByUser(1);

    // Kiểm tra số lượng và tính chính xác của filter
    expect(orders.length, 2);
    expect(orders.every((o) => o.userId == 1), true);
    // Đơn tạo lúc 10:00 phải xếp trước đơn lúc 09:00
    expect(
      orders.first.createdAt,
      DateTime(2026, 9, 22, 10, 0),
    ); // mới nhất trước
  });

  test('getOrderById trả về đúng đơn, null nếu không có', () async {
    final created = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22, 9, 0),
      ),
    );

    final found = await repository.getOrderById(created.id!);
    final notFound = await repository.getOrderById(999);

    // Tìm thấy đúng order đã tạo
    expect(found?.id, created.id);
    // Trả về null khi ID không tồn tại
    expect(notFound, null);
  });

  test('updateOrderStatus đổi đúng trạng thái', () async {
    final created = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 22, 9, 0),
      ),
    );

    // Đổi trạng thái từ pending -> preparing
    await repository.updateOrderStatus(created.id!, OrderStatus.preparing);
    final updated = await repository.getOrderById(created.id!);

    expect(updated?.status, OrderStatus.preparing);
  });

  test('updateOrderStatus ném lỗi khi id không tồn tại', () async {
    // Đảm bảo bắn ra StateError khi id = 999 không có trong danh sách
    expect(
      () => repository.updateOrderStatus(999, OrderStatus.preparing),
      throwsStateError,
    );
  });
}
