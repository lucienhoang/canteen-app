import 'package:canteen_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('dùng Material 3 và seed cam', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, ColorScheme.fromSeed(seedColor: AppTheme.seed));
    });

    test('có màu success trong extension', () {
      final colors = AppTheme.light().extension<AppColors>();
      expect(colors, isNotNull);
      expect(colors!.success, Colors.green.shade700);
    });

    test('lerp giữa hai AppColors cho màu ở giữa', () {
      const a = AppColors(success: Colors.black, onSuccess: Colors.black);
      const b = AppColors(success: Colors.white, onSuccess: Colors.white);
      final mid = a.lerp(b, 0.5);
      expect(mid.success, Color.lerp(Colors.black, Colors.white, 0.5));
    });

    testWidgets('context.appColors đọc được từ widget', (tester) async {
      late AppColors read;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              read = context.appColors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(read.success, Colors.green.shade700);
    });
  });
}
