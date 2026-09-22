import 'package:canteen_app/data/repositories/menu_repository.dart';
import 'package:canteen_app/features/menu/menu_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Kiểm tra lọc logic món ăn theo Danh Mục
  test('lọc theo danh mục chi trả món đúng danh mục', () async {
    // 1. Chuẩn bị: Khởi tạo Viewmodel với dữ liệu Mock
    final vm = MenuViewmodel(MockMenuRepository());

    // 2. Hành động: Tải dữ liệu và chọn danh mục ID = 3 ("Đồ uống")
    await vm.load();
    vm.selectCategory(3);

    // 3. Kiểm tra kết quả:
    // - Đảm bảo mọi món ăn tỏng danh sách visibleItems đều có categoryId = 3
    expect(vm.visibleItems.every((i) => i.categoryId == 3), isTrue);

    // - Đảm bảo tổng số lượng món trả về chính xác là 2 món
    expect(vm.visibleItems.length, 2);
  });
}

// Run in terminal: flutter test test/menu_viewmodel_test.dart
