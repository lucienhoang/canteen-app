import 'package:canteen_app/core/widgets/responsive_center.dart';
import 'package:canteen_app/features/staff/staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('ResponsiveCenter', () {
    testWidgets('màn rộng: giới hạn bề rộng và căn giữa', (tester) async {
      _setScreen(tester, const Size(1000, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              maxWidth: 400,
              child: SizedBox.expand(key: Key('content')),
            ),
          ),
        ),
      );

      final box = find.byKey(const Key('content'));
      expect(tester.getSize(box).width, 400);
      // (1000 - 400) / 2 = 300
      expect(tester.getTopLeft(box).dx, 300);
    });

    testWidgets('màn hẹp: dùng hết bề rộng có sẵn', (tester) async {
      _setScreen(tester, const Size(300, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              maxWidth: 400,
              child: SizedBox.expand(key: Key('content')),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('content'))).width, 300);
    });

    testWidgets('shrinkHeight: chỉ cao bằng nội dung', (tester) async {
      _setScreen(tester, const Size(800, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Spacer(),
                ResponsiveCenter(
                  shrinkHeight: true,
                  child: SizedBox(height: 50),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(ResponsiveCenter)).height, 50);
    });
  });

  group('staffColumnsFor', () {
    test('chia cột theo bề rộng', () {
      expect(staffColumnsFor(360), 1);
      expect(staffColumnsFor(599), 1);
      expect(staffColumnsFor(600), 2);
      expect(staffColumnsFor(899), 2);
      expect(staffColumnsFor(900), 3);
      expect(staffColumnsFor(1200), 3);
    });
  });
}
