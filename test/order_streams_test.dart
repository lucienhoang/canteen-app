import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/menu_item.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/cart/cart_viewmodel.dart';
import 'package:canteen_app/features/orders/order_tracking_viewmodel.dart';
import 'package:canteen_app/features/staff/staff_viewmodel.dart';

/// Nhường một nhịp để các sự kiện bất đồng bộ của stream kịp chạy.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  final sampleOrder = Order(
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
    pickupTime: DateTime(2026, 10, 12, 11, 30),
    createdAt: DateTime(2026, 10, 10, 9, 0),
  );

  group('Order: tên và MSSV', () {
    test('toMap rồi fromMap giữ nguyên tên và MSSV', () {
      final map = sampleOrder.toMap()..['id'] = 7;
      final restored = Order.fromMap(map, sampleOrder.items);
      expect(restored.userName, 'Nguyễn Văn A');
      expect(restored.userMssv, '2110001');
      expect(restored.id, '7');
    });

    test('đơn cũ thiếu hai cột thì tên và MSSV rỗng, không văng lỗi', () {
      final map = sampleOrder.toMap()
        ..remove('user_name')
        ..remove('user_mssv');
      final restored = Order.fromMap(map, sampleOrder.items);
      expect(restored.userName, '');
      expect(restored.userMssv, '');
    });

    test('copyWith giữ nguyên tên và MSSV khi chỉ đổi trạng thái', () {
      final changed = sampleOrder.copyWith(status: OrderStatus.preparing);
      expect(changed.userName, 'Nguyễn Văn A');
      expect(changed.userMssv, '2110001');
    });
  });

  group('CartViewModel.checkout lưu tên và MSSV vào đơn', () {
    test('đơn tạo ra mang đúng tên và MSSV', () async {
      final cart = CartViewModel(orderRepository: MockOrderRepository())
        ..addItem(
          const MenuItem(id: 1, categoryId: 1, name: 'Cơm sườn', price: 35000),
        );

      final order = await cart.checkout(
        userId: 'u1',
        userName: 'Nguyễn Văn A',
        userMssv: '2110001',
        pickupTime: DateTime(2026, 10, 12, 11, 30),
      );

      expect(order?.userName, 'Nguyễn Văn A');
      expect(order?.userMssv, '2110001');
    });
  });

  group('MockOrderRepository.watchAllOrders', () {
    test('phát danh sách hiện tại, rồi phát lại khi có đơn mới', () async {
      final repo = MockOrderRepository();
      final counts = <int>[];
      final sub = repo.watchAllOrders().listen((o) => counts.add(o.length));

      await settle();
      expect(counts, [0]);

      await repo.createOrder(sampleOrder);
      await settle();
      expect(counts, [0, 1]);

      await sub.cancel();
    });

    test('phát lại khi đơn đổi trạng thái', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      final statuses = <OrderStatus>[];
      final sub = repo.watchAllOrders().listen(
        (orders) => statuses.add(orders.first.status),
      );
      await settle();

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();

      expect(statuses, [OrderStatus.pending, OrderStatus.preparing]);
      await sub.cancel();
    });

    test('hủy nghe rồi thì không nhận thêm gì nữa', () async {
      final repo = MockOrderRepository();
      var emissions = 0;
      final sub = repo.watchAllOrders().listen((_) => emissions++);
      await settle();
      await sub.cancel();

      await repo.createOrder(sampleOrder);
      await settle();
      expect(emissions, 1); // chỉ lần phát đầu tiên
    });
  });

  group('MockOrderRepository.watchOrder', () {
    test('phát đơn hiện tại và các lần đổi trạng thái', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      final statuses = <OrderStatus?>[];
      final sub = repo
          .watchOrder(saved.id!)
          .listen((o) => statuses.add(o?.status));
      await settle();

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();

      expect(statuses, [OrderStatus.pending, OrderStatus.preparing]);
      await sub.cancel();
    });

    test('id không tồn tại thì phát null', () async {
      final repo = MockOrderRepository();
      final values = <Order?>[];
      final sub = repo.watchOrder('khong-co').listen(values.add);
      await settle();

      expect(values, [null]);
      await sub.cancel();
    });

    test('chỉ phát lại đơn mình theo dõi vẫn đúng khi đơn khác đổi', () async {
      final repo = MockOrderRepository();
      final a = await repo.createOrder(sampleOrder);
      final b = await repo.createOrder(sampleOrder);
      final statuses = <OrderStatus?>[];
      final sub = repo.watchOrder(a.id!).listen((o) => statuses.add(o?.status));
      await settle();

      await repo.updateOrderStatus(b.id!, OrderStatus.preparing);
      await settle();

      // Đơn A không đổi: dù có phát lại thì trạng thái của A vẫn là pending
      expect(statuses.every((s) => s == OrderStatus.pending), true);
      await sub.cancel();
    });
  });

  group('StaffViewModel.startWatching', () {
    test('tự cập nhật khi có đơn mới và khi đổi trạng thái', () async {
      final repo = MockOrderRepository();
      final vm = StaffViewModel(
        orderRepository: repo,
        onStatusChanged: (_) async {},
      );

      vm.startWatching();
      await settle();
      expect(vm.isLoading, false);
      expect(vm.activeOrders, isEmpty);

      final saved = await repo.createOrder(sampleOrder);
      await settle();
      expect(vm.activeOrders.length, 1);

      await vm.changeStatus(saved, OrderStatus.preparing);
      await settle();
      expect(vm.activeOrders.first.status, OrderStatus.preparing);

      vm.dispose();
    });

    test('đơn bị hủy biến mất khỏi danh sách đang xử lý', () async {
      final repo = MockOrderRepository();
      final vm = StaffViewModel(
        orderRepository: repo,
        onStatusChanged: (_) async {},
      );
      final saved = await repo.createOrder(sampleOrder);

      vm.startWatching();
      await settle();
      expect(vm.activeOrders.length, 1);

      await vm.changeStatus(saved, OrderStatus.cancelled);
      await settle();
      expect(vm.activeOrders, isEmpty);

      vm.dispose();
    });

    test('gọi startWatching nhiều lần vẫn chỉ đăng ký một lần', () async {
      final repo = MockOrderRepository();
      final vm = StaffViewModel(
        orderRepository: repo,
        onStatusChanged: (_) async {},
      );
      var notifications = 0;
      vm.addListener(() => notifications++);

      vm.startWatching();
      vm.startWatching();
      vm.startWatching();
      await settle();

      // 1 lần bật loading + 1 lần nhận dữ liệu đầu tiên
      expect(notifications, 2);
      vm.dispose();
    });

    test('dispose rồi thì thay đổi sau đó không gây lỗi', () async {
      final repo = MockOrderRepository();
      final vm = StaffViewModel(
        orderRepository: repo,
        onStatusChanged: (_) async {},
      );
      vm.startWatching();
      await settle();
      vm.dispose();

      // Nếu subscription chưa bị hủy, dòng này sẽ làm notifyListeners trên VM đã dispose
      await repo.createOrder(sampleOrder);
      await settle();
    });
  });

  group('OrderTrackingViewModel.watchOrder', () {
    test('nhận đơn rồi tự cập nhật khi nhân viên đổi trạng thái', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      final vm = OrderTrackingViewModel(orderRepository: repo);

      vm.watchOrder(saved.id!);
      await settle();
      expect(vm.isLoading, false);
      expect(vm.order?.status, OrderStatus.pending);

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();
      expect(vm.order?.status, OrderStatus.preparing);

      vm.dispose();
    });

    test('id không tồn tại thì báo lỗi "Không tìm thấy đơn hàng"', () async {
      final vm = OrderTrackingViewModel(orderRepository: MockOrderRepository());

      vm.watchOrder('khong-co');
      await settle();

      expect(vm.errorMessage, 'Không tìm thấy đơn hàng');
      expect(vm.isLoading, false);
      vm.dispose();
    });

    test('dispose rồi thì thay đổi sau đó không gây lỗi', () async {
      final repo = MockOrderRepository();
      final saved = await repo.createOrder(sampleOrder);
      final vm = OrderTrackingViewModel(orderRepository: repo);
      vm.watchOrder(saved.id!);
      await settle();
      vm.dispose();

      await repo.updateOrderStatus(saved.id!, OrderStatus.preparing);
      await settle();
    });
  });
}
