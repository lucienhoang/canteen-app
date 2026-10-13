import 'package:canteen_app/core/network/connectivity_viewmodel.dart';
import 'package:canteen_app/core/widgets/connectivity_banner_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_connectivity_service.dart';

void main() {
  testWidgets('hiện dải thông báo khi offline, ẩn khi online', (tester) async {
    final fake = FakeConnectivityService(online: true);
    final vm = ConnectivityViewModel(fake);

    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectivityViewModel>.value(
        value: vm,
        child: MaterialApp(
          builder: (context, child) => ConnectivityBannerHost(child: child!),
          home: const Scaffold(body: Text('nội dung')),
        ),
      ),
    );

    const message = ConnectivityBannerHost.offlineMessage;
    expect(find.text('nội dung'), findsOneWidget);
    expect(find.text(message), findsNothing);

    fake.setOnline(false);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    expect(find.text('nội dung'), findsOneWidget); // nội dung vẫn còn

    fake.setOnline(true);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);

    // Gỡ widget trước rồi mới dispose, tránh dùng ViewModel đã hủy.
    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
    await fake.dispose();
  });
}
