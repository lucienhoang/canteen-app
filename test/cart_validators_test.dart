import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/features/cart/cart_validators.dart';

void main() {
  group('Kiểm tra hàm validatePickupTime', () {
    test('Khác ngày -> báo lỗi', () {
      final now = DateTime(2026, 10, 19, 10, 0);
      final picked = DateTime(2026, 10, 20, 10, 0); // Ngày hôm sau
      final result = validatePickupTime(picked, now);
      expect(result, 'Chỉ được chọn giờ lấy trong ngày hôm nay.');
    });

    test('Trước 10 phút (ví dụ 9 phút) -> báo lỗi', () {
      final now = DateTime(2026, 10, 19, 10, 0);
      final picked = DateTime(2026, 10, 19, 10, 9);
      final result = validatePickupTime(picked, now);
      expect(result, 'Giờ lấy phải cách thời điểm đặt ít nhất 10 phút.');
    });

    test('Đúng 10 phút -> hợp lệ (trả về null)', () {
      final now = DateTime(2026, 10, 19, 10, 0);
      final picked = DateTime(2026, 10, 19, 10, 10);
      final result = validatePickupTime(picked, now);
      expect(result, isNull);
    });

    test('Sau 10 phút -> hợp lệ (trả về null)', () {
      final now = DateTime(2026, 10, 19, 10, 0);
      final picked = DateTime(2026, 10, 19, 10, 30);
      final result = validatePickupTime(picked, now);
      expect(result, isNull);
    });
  });
}