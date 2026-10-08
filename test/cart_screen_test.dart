import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:canteen_app/data/repositories/auth_repository.dart';
import 'package:canteen_app/data/repositories/order_repository.dart';
import 'package:canteen_app/features/auth/auth_viewmodel.dart';
import 'package:canteen_app/features/cart/cart_screen.dart';
import 'package:canteen_app/features/cart/cart_viewmodel.dart';

void main() {
  /// Dựng môi trường test hoàn chỉnh: giỏ hàng + (tuỳ chọn) người dùng đã đăng nhập.
  /// [signedIn] = false để thử trường hợp chưa đăng nhập.
  Future<Widget> buildTestApp({bool signedIn = true}) async {
    // MockAuthRepository không có Future.delayed nên await trực tiếp được,
    // không cần tester.runAsync.
    final auth = AuthViewModel(authRepository: MockAuthRepository());
    if (signedIn) {
      await auth.signIn('2110001', '123456');
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => CartViewModel(orderRepository: MockOrderRepository()),
        ),
      ],
      child: const MaterialApp(home: CartScreen()),
    );
  }

  testWidgets('hiện danh sách món demo và tổng tiền đúng', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    // Chờ addPostFrameCallback trong initState chạy xong để nạp món demo
    await tester.pumpAndSettle();

    // Kiểm tra các item demo có hiển thị trên màn hình
    expect(find.text('Cơm Sườn'), findsOneWidget);
    expect(find.text('Trà đá'), findsOneWidget);
    // Tổng tiền dự kiến: 35.000 + 5.000 = 40.000đ
    expect(find.text('40.000đ'), findsOneWidget);
  });

  testWidgets('bấm nút + tăng số lượng và cập nhật tổng tiền', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    // Bấm nút + của món Cơm Sườn (nút icon add_circle_outline đầu tiên)
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester
        .pumpAndSettle(); // Cập nhật lại giao diện sau khi tăng số lượng

    // Cơm sườn từ 1 lên 2: (35.000 * 2) + 5.000 = 75.000đ
    expect(find.text('75.000đ'), findsOneWidget);
  });

  testWidgets('bấm nút xoá thì món biến mất khỏi giỏ', (tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    // Bấm nút xóa dòng món đầu tiên (Cơm Sườn)
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    // Xác minh Cơm Sườn đã bị gỡ hoàn toàn khỏi giao diện
    expect(find.text('Cơm Sườn'), findsNothing);
  });

  testWidgets(
    'bấm Đặt đơn thành công thì hiện SnackBar và giỏ về trạng thái trống',
    (tester) async {
      await tester.pumpWidget(await buildTestApp());
      await tester.pumpAndSettle();

      // Bấm nút "Đặt đơn"
      await tester.tap(find.text('Đặt đơn'));
      await tester.pump(); // Bắt đầu trạng thái loading (isSubmitting = true)

      // Tua nhanh qua thời gian delay 800ms của MockOrderRepository
      await tester.pump(const Duration(milliseconds: 900));

      // Kiểm tra thông báo SnackBar thành công và màn hình báo giỏ trống
      expect(find.textContaining('Đặt đơn thành công'), findsOneWidget);
      expect(find.text('Giỏ hàng trống'), findsOneWidget);
    },
  );

  testWidgets('checkout thành công thì điều hướng sang OrderTrackingScreen', (
    tester,
  ) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt đơn'));
    await tester.pump(); // bắt đầu loading
    await tester.pump(
      const Duration(milliseconds: 900),
    ); // qua delay 800ms giả lập
    await tester.pumpAndSettle(); // đợi animation chuyển trang xong

    expect(find.text('Theo dõi đơn hàng'), findsOneWidget);
  });

  testWidgets('chưa đăng nhập thì bấm Đặt đơn không tạo đơn', (tester) async {
    // AuthViewModel chưa signIn -> currentUser == null
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đặt đơn'));
    await tester.pumpAndSettle();

    // Không có SnackBar thành công, giỏ vẫn còn món
    expect(find.textContaining('Đặt đơn thành công'), findsNothing);
    expect(find.text('Cơm Sườn'), findsOneWidget);
  });
}
