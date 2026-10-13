import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/connectivity_guarded_order_repository.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/data/repositories/order_repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_connectivity_service.dart';

/// Repository giả có đếm số lần bị gọi, để chứng minh khi offline
/// lớp bọc ngoài chặn lại và KHÔNG chuyển xuống repository bên trong.
class _SpyRepository extends MockOrderRepository {
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Order> createOrder(Order order) {
    createCalls++;
    return super.createOrder(order);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    updateCalls++;
    return super.updateOrderStatus(orderId, newStatus);
  }
}

void main() {
  final order = Order(
    userId: 'u1',
    userName: 'Nguyễn Văn A',
    userMssv: '2110001',
    items: const [
      OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 1,
      ),
    ],
    pickupTime: DateTime(2026, 10, 15, 11, 30),
    createdAt: DateTime(2026, 10, 15, 9, 0),
  );

  late FakeConnectivityService connectivity;
  late _SpyRepository inner;
  late ConnectivityGuardedOrderRepository guarded;

  Matcher offlineError() => throwsA(
    isA<OrderRepositoryException>().having(
      (e) => e.message,
      'message',
      ConnectivityGuardedOrderRepository.offlineMessage,
    ),
  );

  setUp(() {
    connectivity = FakeConnectivityService(online: true);
    inner = _SpyRepository();
    guarded = ConnectivityGuardedOrderRepository(inner, connectivity);
  });

  tearDown(() => connectivity.dispose());

  test(
    'offline: createOrder bị từ chối và không gọi repository bên trong',
    () async {
      connectivity.setOnline(false);

      await expectLater(guarded.createOrder(order), offlineError());
      expect(inner.createCalls, 0);
    },
  );

  test(
    'offline: updateOrderStatus bị từ chối và không gọi repository bên trong',
    () async {
      connectivity.setOnline(false);

      await expectLater(
        guarded.updateOrderStatus('1', OrderStatus.preparing),
        offlineError(),
      );
      expect(inner.updateCalls, 0);
    },
  );

  test('online: createOrder được chuyển tiếp và trả về đơn có id', () async {
    final saved = await guarded.createOrder(order);

    expect(inner.createCalls, 1);
    expect(saved.id, isNotNull);
  });

  test('offline: vẫn đọc và theo dõi được dữ liệu đã có', () async {
    connectivity.setOnline(false);

    expect(await guarded.getAllOrders(), isEmpty);
    expect(await guarded.watchAllOrders().first, isEmpty);
  });
}
