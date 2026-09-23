import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/menu_item.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/cart/cart_viewmodel.dart';

void main() {
  late CartViewModel viewModel;

  // Khai báo các món ăn mẫu phục vụ test
  const comSuon = MenuItem(
    id: 1,
    categoryId: 1,
    name: 'Cơm sườn',
    price: 35000,
  );
  const traDa = MenuItem(id: 2, categoryId: 2, name: 'Trà đá', price: 5000);

  // Khởi tạo lại ViewModel sạch trước mỗi bài test
  setUp(() {
    viewModel = CartViewModel(orderRepository: MockOrderRepository());
  });

  test('addItem thêm món mới vào giỏ', () {
    viewModel.addItem(comSuon);

    expect(viewModel.items.length, 1);
    expect(viewModel.items.first.quantity, 1);
  });

  test('addItem 2 lần cùng 1 món thì gộp quantity, không tạo dòng mới', () {
    viewModel.addItem(comSuon);
    viewModel.addItem(comSuon);

    expect(viewModel.items.length, 1);
    expect(viewModel.items.first.quantity, 2);
  });

  test('totalAmount cộng dồn đúng khi có nhiều món khác nhau', () {
    viewModel.addItem(comSuon); // 35.000
    viewModel.addItem(traDa); // 5.000
    viewModel.addItem(traDa); // +5.000 -> quantity = 2

    // Phép tính: 35.000 + (5.000 * 2) = 45.000
    expect(viewModel.totalAmount, 45000);
  });

  test('updateQuantity đổi đúng số lượng', () {
    viewModel.addItem(comSuon);
    viewModel.updateQuantity(comSuon.id, 5);

    expect(viewModel.items.first.quantity, 5);
  });

  test('updateQuantity về 0 thì tự xoá dòng khỏi giỏ', () {
    viewModel.addItem(comSuon);
    viewModel.updateQuantity(comSuon.id, 0);

    expect(viewModel.isEmpty, true);
  });

  test('removeItem xoá đúng món', () {
    viewModel.addItem(comSuon);
    viewModel.addItem(traDa);
    viewModel.removeItem(comSuon.id);

    expect(viewModel.items.length, 1);
    expect(viewModel.items.first.menuItemId, traDa.id);
  });

  test('checkout với giỏ trống trả về null và báo lỗi', () async {
    final result = await viewModel.checkout(
      userId: 1,
      pickupTime: DateTime(2026, 10, 1, 11, 30),
    );

    expect(result, null);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('checkout thành công thì trả về Order và xoá giỏ', () async {
    viewModel.addItem(comSuon);
    viewModel.addItem(traDa);

    final result = await viewModel.checkout(
      userId: 1,
      pickupTime: DateTime(2026, 10, 1, 11, 30),
      note: 'Ít cay',
    );

    // Kiểm tra Order trả về
    expect(result, isNotNull);
    expect(result!.id, isNotNull); // Đã được MockOrderRepository gán ID
    expect(result.userId, 1);
    expect(result.note, 'Ít cay');
    expect(result.totalAmount, 40000);

    // Kiểm tra dọn dẹp state sau checkout
    expect(viewModel.isEmpty, true); // Giỏ đã được xóa sạch
    expect(viewModel.isSubmitting, false); // Đã tắt trạng thái submitting
  });
}
