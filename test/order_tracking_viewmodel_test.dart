import 'package:flutter_test/flutter_test.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/orders/order_tracking_viewmodel.dart';

void main() {
  late MockOrderRepository repository;
  late OrderTrackingViewModel viewModel;

  setUp(() {
    repository = MockOrderRepository();
    viewModel = OrderTrackingViewModel(orderRepository: repository);
  });

  final sampleItems = [
    const OrderItem(
      menuItemId: 1,
      menuItemName: 'Cơm sườn',
      priceAtOrder: 35000,
      quantity: 1,
    ),
  ];

  test('loadOrder tải đúng đơn theo id', () async {
    final created = await repository.createOrder(
      Order(
        userId: 1,
        items: sampleItems,
        pickupTime: DateTime(2026, 10, 1, 11, 30),
        createdAt: DateTime(2026, 9, 25, 9, 0),
      ),
    );

    await viewModel.loadOrder(created.id!);

    expect(viewModel.order?.id, created.id);
    expect(viewModel.isLoading, false);
    expect(viewModel.errorMessage, null);
  });

  test('loadOrder với id không tồn tại thì báo lỗi', () async {
    await viewModel.loadOrder(999);

    expect(viewModel.order, null);
    expect(viewModel.errorMessage, isNotNull);
  });
}
