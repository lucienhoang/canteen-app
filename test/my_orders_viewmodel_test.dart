import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/orders/my_orders_viewmodel.dart';

// --- TẠO MOCK REPOSITORY ĐỂ GIẢ LẬP STREAM ---
// Lớp này giúp chúng ta chủ động bơm dữ liệu (giả) vào luồng stream
// để xem ViewModel xử lý có đúng không.
class MockStreamOrderRepository implements OrderRepository {
  final StreamController<List<Order>> controller = StreamController<List<Order>>.broadcast();

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) {
    return controller.stream; // Trả về stream do chúng ta kiểm soát
  }

  // Các hàm khác không dùng trong test này nên để trống
  @override
  Future<List<Order>> getAllOrders() {
    // TODO: implement getAllOrders
    throw UnimplementedError();
  }

  @override
  Future<Order?> getOrderById(String id) {
    // TODO: implement getOrderById
    throw UnimplementedError();
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) {
    // TODO: implement getOrdersByUser
    throw UnimplementedError();
  }

  @override
  Stream<List<Order>> watchAllOrders() {
    // TODO: implement watchAllOrders
    throw UnimplementedError();
  }

  @override
  Future<Order> createOrder(Order order) {
    // TODO: implement createOrder
    throw UnimplementedError();
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) {
    // TODO: implement updateOrderStatus
    throw UnimplementedError();
  }

  @override
  Stream<Order?> watchOrder(String id) {
    // TODO: implement watchOrder
    throw UnimplementedError();
  }
}

void main() {
  group('MyOrdersViewModel Tests', () {
    late MockStreamOrderRepository repository;
    late MyOrdersViewModel viewModel;

    setUp(() {
      repository = MockStreamOrderRepository();
      viewModel = MyOrdersViewModel(
        userId: '2110001', // User ID của sinh viên test
        orderRepository: repository,
      );
    });

    tearDown(() {
      viewModel.dispose();
      repository.controller.close();
    });

    // Hàm tiện ích giúp tạo nhanh 1 Order giả với các trạng thái khác nhau
    Order createOrder({
      required String id,
      required OrderStatus status,
      required DateTime createdAt,
    }) {
      return Order(
        id: id,
        userId: '2110001',
        userName: 'Sinh Vien',
        userMssv: '2110001',
        items: [], // Không quan tâm món ăn trong test này
        pickupTime: DateTime.now().add(const Duration(minutes: 30)),
        status: status,
        createdAt: createdAt,
      );
    }

    test('Không có đơn nào thì danh sách rỗng (count = 0)', () async {
      // Đẩy mảng rỗng vào stream
      repository.controller.add([]);

      // Chờ luồng stream chạy (microtask)
      await Future.delayed(Duration.zero);

      expect(viewModel.activeOrders.length, 0);
    });

    test('Chỉ lấy đơn đang xử lý, loại bỏ completed và cancelled', () async {
      repository.controller.add([
        createOrder(id: '1', status: OrderStatus.pending, createdAt: DateTime.now()),
        createOrder(id: '2', status: OrderStatus.completed, createdAt: DateTime.now()),
        createOrder(id: '3', status: OrderStatus.cancelled, createdAt: DateTime.now()),
        createOrder(id: '4', status: OrderStatus.preparing, createdAt: DateTime.now()),
      ]);

      await Future.delayed(Duration.zero);

      // Kết quả mong muốn: Chỉ còn pending (1) và processing (4)
      expect(viewModel.activeOrders.length, 2);
      expect(viewModel.activeOrders.any((o) => o.id == '1'), isTrue);
      expect(viewModel.activeOrders.any((o) => o.id == '4'), isTrue);

      // Đảm bảo không có completed (2) và cancelled (3)
      expect(viewModel.activeOrders.any((o) => o.id == '2'), isFalse);
      expect(viewModel.activeOrders.any((o) => o.id == '3'), isFalse);
    });

    test('Sắp xếp đơn mới nhất ở trên (createdAt giảm dần)', () async {
      final now = DateTime.now();
      repository.controller.add([
        createOrder(id: 'don_cu_nhat', status: OrderStatus.pending, createdAt: now.subtract(const Duration(minutes: 30))),
        createOrder(id: 'don_moi_nhat', status: OrderStatus.pending, createdAt: now),
        createOrder(id: 'don_hoi_cu', status: OrderStatus.pending, createdAt: now.subtract(const Duration(minutes: 10))),
      ]);

      await Future.delayed(Duration.zero);

      // Kết quả mong muốn: mới nhất -> hơi cũ -> cũ nhất
      expect(viewModel.activeOrders.length, 3);
      expect(viewModel.activeOrders[0].id, 'don_moi_nhat');
      expect(viewModel.activeOrders[1].id, 'don_hoi_cu');
      expect(viewModel.activeOrders[2].id, 'don_cu_nhat');
    });
  });
}