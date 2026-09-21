import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/order_status.dart';

void main() {
  group('OrderStatus transitions', () {
    test('pending can move to preparing', () {
      expect(OrderStatus.pending.canChangeTo(OrderStatus.preparing), true);
    });

    test('pending cannot jump to completed', () {
      expect(OrderStatus.pending.canChangeTo(OrderStatus.completed), false);
    });

    test('completed is a final state', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.completed.canChangeTo(s), false);
      }
    });

    test('cannot cancel once ready', () {
      expect(OrderStatus.ready.canChangeTo(OrderStatus.cancelled), false);
    });
  });
}
