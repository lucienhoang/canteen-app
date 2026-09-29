import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/staff/staff_viewmodel.dart';

void main() {
  late MockOrderRepository repository;
  late StaffViewModel viewModel;

  final sampleItems = [
    const OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 1,
    ),
  ];

  setUp(() {
    repository = MockOrderRepository();
    viewModel = StaffViewModel(
      orderRepository: repository,
      onStatusChanged: (_) async {}, // bỏ qua thông báo thật khi test
    );
  });

  test('activeOrders bỏ qua đơn completed và cancelled', () async {
    final o1 = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 26, 9, 0),
      ),
    );
    final o2 = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 12, 0),
        createdAt: DateTime(2026, 9, 26, 9, 5),
      ),
    );
    await repository.updateOrderStatus(o2.id!, OrderStatus.preparing);
    await repository.updateOrderStatus(o2.id!, OrderStatus.ready);
    await repository.updateOrderStatus(o2.id!, OrderStatus.completed);

    await viewModel.loadOrders();

    expect(viewModel.activeOrders.length, 1);
    expect(viewModel.activeOrders.first.id, o1.id);
  });

  test('changeStatus đổi đúng trạng thái khi hợp lệ', () async {
    final order = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 26, 9, 0),
      ),
    );
    await viewModel.loadOrders();

    await viewModel.changeStatus(order, OrderStatus.preparing);

    expect(
      viewModel.activeOrders.firstWhere((o) => o.id == order.id).status,
      OrderStatus.preparing,
    );
  });

  test('changeStatus bỏ qua khi chuyển trạng thái không hợp lệ', () async {
    final order = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 26, 9, 0),
      ),
    );
    await viewModel.loadOrders();

    // pending không thể nhảy thẳng sang completed
    await viewModel.changeStatus(order, OrderStatus.completed);

    expect(
      viewModel.activeOrders.firstWhere((o) => o.id == order.id).status,
      OrderStatus.pending,
    );
  });
}
