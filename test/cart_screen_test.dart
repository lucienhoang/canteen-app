import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:canteen_app/data/models/menu_item.dart';
import 'package:canteen_app/data/models/order.dart'; // Thêm import Order
import 'package:canteen_app/data/repositories/auth_repository.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/auth/auth_viewmodel.dart';
import 'package:canteen_app/features/cart/cart_screen.dart';
import 'package:canteen_app/features/cart/cart_viewmodel.dart';

/// Lớp Mock tùy chỉnh để "tóm" lấy đơn hàng trước khi gửi đi,
/// giúp ta kiểm tra xem ghi chú có được truyền vào đúng không.
class NoteCaptureOrderRepository extends MockOrderRepository {
  String? capturedNote;
  bool wasCalled = false;

  @override
  Future<Order> createOrder(Order order) async {
    wasCalled = true;
    capturedNote = order.note; // Bắt lấy ghi chú
    return super.createOrder(order);
  }
}

void main() {
  /// Dựng môi trường test hoàn chỉnh: giỏ hàng có sẵn 2 món + (tuỳ chọn) người dùng đã đăng nhập.
  /// Thêm tham số [repository] để có thể truyền Mock tùy chỉnh vào.
  Future<Widget> buildTestApp({
    bool signedIn = true,
    OrderRepository? repository,
  }) async {
    final auth = AuthViewModel(MockAuthRepository());
    final repo = repository ?? MockOrderRepository();

    if (signedIn) {
      await auth.signIn('2110001', '123456');
    }

    final cart = CartViewModel(orderRepository: repo)
      ..addItem(
        const MenuItem(id: 1, categoryId: 1, name: 'Cơm Sườn', price: 35000),
      )
      ..addItem(
        const MenuItem(id: 2, categoryId: 2, name: 'Trà đá', price: 5000),
      );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<CartViewModel>.value(value: cart),
      ],
      child: MaterialApp(home: CartScreen(orderRepository: repo)),
    );
  }

  testWidgets('hiện danh sách món trong giỏ và tổng tiền đúng', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Cơm Sườn'), findsOneWidget);
    expect(find.text('Trà đá'), findsOneWidget);
    expect(find.text('40.000đ'), findsOneWidget);
  });

  testWidgets('bấm nút + tăng số lượng và cập nhật tổng tiền', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('75.000đ'), findsOneWidget);
  });

  testWidgets('bấm nút xoá thì món biến mất khỏi giỏ', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Cơm Sườn'), findsNothing);
  });

  testWidgets('giỏ trống thì hiện "Giỏ hàng trống" và khóa nút Đặt đơn', (tester) async {
    final auth = AuthViewModel(MockAuthRepository());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          ChangeNotifierProvider(
            create: (_) => CartViewModel(orderRepository: MockOrderRepository()),
          ),
        ],
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giỏ hàng trống'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('bấm Đặt đơn thành công thì hiện SnackBar và giỏ về trạng thái trống', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt đơn'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 900));

    expect(find.textContaining('Đặt đơn thành công'), findsOneWidget);
    expect(find.text('Giỏ hàng trống'), findsOneWidget);
  },
  );

  testWidgets('checkout thành công thì điều hướng sang OrderTrackingScreen', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt đơn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Theo dõi đơn hàng'), findsOneWidget);
  });

  testWidgets('chưa đăng nhập thì bấm Đặt đơn không tạo đơn', (tester) async {
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt đơn'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đặt đơn thành công'), findsNothing);
    expect(find.text('Cơm Sườn'), findsOneWidget);
  });

  // --- 2 TEST MỚI THÊM VÀO ---

  testWidgets('nhập ghi chú rồi đặt đơn với MockOrderRepository thì đơn có note', (tester) async {
    final repo = NoteCaptureOrderRepository();
    await tester.pumpWidget(await buildTestApp(repository: repo));
    await tester.pumpAndSettle();

    // Tìm và cuộn đến ô nhập ghi chú
    final textField = find.byType(TextField);
    await tester.ensureVisible(textField);

    // Nhập nội dung
    await tester.enterText(textField, 'Xin thêm nhiều tương ớt');
    await tester.pumpAndSettle();

    // Bấm đặt đơn
    await tester.tap(find.text('Đặt đơn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Kiểm tra repository đã bắt được đúng note chưa
    expect(repo.wasCalled, isTrue);
    expect(repo.capturedNote, 'Xin thêm nhiều tương ớt');
  });

  testWidgets('ghi chú trống (hoặc toàn dấu cách) thì note == null', (tester) async {
    final repo = NoteCaptureOrderRepository();
    await tester.pumpWidget(await buildTestApp(repository: repo));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.ensureVisible(textField);

    // Cố tình nhập toàn dấu cách (khoảng trắng)
    await tester.enterText(textField, '    ');
    await tester.pumpAndSettle();

    // Bấm đặt đơn
    await tester.tap(find.text('Đặt đơn'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Kiểm tra repository nhận được giá trị null thay vì chuỗi rỗng
    expect(repo.wasCalled, isTrue);
    expect(repo.capturedNote, isNull);
  });
}