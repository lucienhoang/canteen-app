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
  /// Kiểm tra logic tìm kiếm món ăn
  test('search() lọc đúng món ăn theo tên không phân biệt hoa/thường', () async {
    // 1. Chuẩn bị: Khởi tạo ViewModel với dữ liệu Mock
    final vm = MenuViewmodel(MockMenuRepository());

    // Tải dữ liệu
    await vm.load();

    // 2. Hành động: Lấy 1 phần tên của món đầu tiên (chuyển sang chữ thường) để làm từ khoá tìm kiếm
    final firstItemName = vm.visibleItems.first.name;
    final query = firstItemName.substring(0, 2).toLowerCase();

    vm.search(query);

    // 3. Kiểm tra kết quả:
    expect(vm.visibleItems.isNotEmpty, isTrue);

    // - Đảm bảo TẤT CẢ các món ăn hiển thị đều chứa chuỗi tìm kiếm (đã chuyển chữ thường)
    expect(vm.visibleItems.every((i) => i.name.toLowerCase().contains(query)), isTrue);
  });
}

// Run in terminal: flutter test test/menu_viewmodel_test.dart
