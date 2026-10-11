import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';

import 'package:canteen_app/data/models/order.dart';
import 'package:canteen_app/data/models/order_item.dart';
import 'package:canteen_app/data/models/order_status.dart';
import 'package:canteen_app/data/repositories/firestore_order_repository.dart';
import 'package:canteen_app/data/repositories/order_repository_exception.dart';

/// Firestore thật không chạy được trong `flutter test`, nên ở đây chỉ test phần
/// logic thuần (chuyển đổi dữ liệu, ánh xạ lỗi). Việc ghi/đọc thật được kiểm
/// chứng bằng test tay trên hai thiết bị.
void main() {
  final order = Order(
    userId: 'uid-1',
    userName: 'Nguyễn Văn A',
    userMssv: '2110001',
    items: const [
      OrderItem(
        menuItemId: 1,
        menuItemName: 'Cơm sườn',
        priceAtOrder: 35000,
        quantity: 2,
      ),
      OrderItem(
        menuItemId: 2,
        menuItemName: 'Trà đá',
        priceAtOrder: 5000,
        quantity: 1,
      ),
    ],
    status: OrderStatus.preparing,
    pickupTime: DateTime(2026, 10, 12, 11, 30),
    note: 'Ít cơm',
    createdAt: DateTime(2026, 10, 12, 10, 0),
  );

  group('orderToData', () {
    test('chứa đủ trường, không chứa id', () {
      final data = FirestoreOrderRepository.orderToData(order);

      expect(data['userId'], 'uid-1');
      expect(data['userName'], 'Nguyễn Văn A');
      expect(data['userMssv'], '2110001');
      expect(data['status'], 'preparing');
      expect(data['note'], 'Ít cơm');
      expect(data['pickupTime'], isA<Timestamp>());
      expect(data['createdAt'], isA<Timestamp>());
      expect(data.containsKey('id'), false);
    });

    test('món lưu dạng mảng và có tổng tiền', () {
      final data = FirestoreOrderRepository.orderToData(order);

      final items = data['items'] as List;
      expect(items.length, 2);
      expect((items.first as Map)['menuItemName'], 'Cơm sườn');
      expect((items.first as Map)['priceAtOrder'], 35000);
      expect(data['totalAmount'], 75000); // 35.000 x 2 + 5.000
    });
  });

  group('orderFromData', () {
    test('toData rồi fromData trả lại đúng đơn', () {
      final data = FirestoreOrderRepository.orderToData(order);
      final restored = FirestoreOrderRepository.orderFromData('abc123', data);

      expect(restored.id, 'abc123');
      expect(restored.userId, 'uid-1');
      expect(restored.userName, 'Nguyễn Văn A');
      expect(restored.userMssv, '2110001');
      expect(restored.status, OrderStatus.preparing);
      expect(restored.note, 'Ít cơm');
      expect(restored.pickupTime, DateTime(2026, 10, 12, 11, 30));
      expect(restored.createdAt, DateTime(2026, 10, 12, 10, 0));
      expect(restored.items.length, 2);
      expect(restored.items.first.menuItemName, 'Cơm sườn');
      expect(restored.items.first.quantity, 2);
      expect(restored.totalAmount, 75000);
    });

    test('trạng thái lạ rơi về pending, không văng lỗi', () {
      final data = FirestoreOrderRepository.orderToData(order)
        ..['status'] = 'khong-hop-le';
      final restored = FirestoreOrderRepository.orderFromData('x', data);
      expect(restored.status, OrderStatus.pending);
    });

    test('document thiếu dữ liệu vẫn đọc được với giá trị an toàn', () {
      final restored = FirestoreOrderRepository.orderFromData('x', {});

      expect(restored.id, 'x');
      expect(restored.userName, '');
      expect(restored.userMssv, '');
      expect(restored.items, isEmpty);
      expect(restored.status, OrderStatus.pending);
      expect(restored.note, isNull);
    });
  });

  group('messageForCode', () {
    test('mất mạng và hết thời gian dùng chung thông báo kết nối', () {
      expect(
        FirestoreOrderRepository.messageForCode('unavailable'),
        contains('kết nối mạng'),
      );
      expect(
        FirestoreOrderRepository.messageForCode('deadline-exceeded'),
        contains('kết nối mạng'),
      );
    });

    test('thiếu quyền có thông báo riêng', () {
      expect(
        FirestoreOrderRepository.messageForCode('permission-denied'),
        contains('không có quyền'),
      );
    });

    test('hết phiên đăng nhập có thông báo riêng', () {
      expect(
        FirestoreOrderRepository.messageForCode('unauthenticated'),
        contains('đăng nhập lại'),
      );
    });

    test('mã lỗi lạ rơi về thông báo chung', () {
      expect(
        FirestoreOrderRepository.messageForCode('abc-xyz'),
        'Có lỗi xảy ra, thử lại nhé',
      );
    });
  });

  group('OrderRepositoryException', () {
    test('mang đúng thông báo', () {
      const e = OrderRepositoryException('Lỗi thử');
      expect(e.message, 'Lỗi thử');
      expect(e.toString(), contains('Lỗi thử'));
    });
  });
}
