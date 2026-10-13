import 'package:canteen_app/core/network/connectivity_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_connectivity_service.dart';

void main() {
  test(
    'đang online, chuyển offline thì isOnline = false và thông báo 1 lần',
    () async {
      final fake = FakeConnectivityService(online: true);
      final vm = ConnectivityViewModel(fake);
      var notified = 0;
      vm.addListener(() => notified++);

      await Future<void>.delayed(
        Duration.zero,
      ); // cho lần kiểm tra ban đầu chạy xong
      expect(vm.isOnline, isTrue);
      expect(notified, 0);

      fake.setOnline(false);
      await Future<void>.delayed(Duration.zero);
      expect(vm.isOnline, isFalse);
      expect(notified, 1);

      vm.dispose();
      await fake.dispose();
    },
  );

  test('mở app khi đang offline thì cập nhật isOnline = false', () async {
    final fake = FakeConnectivityService(online: false);
    final vm = ConnectivityViewModel(fake);

    await Future<void>.delayed(Duration.zero);
    expect(vm.isOnline, isFalse);

    vm.dispose();
    await fake.dispose();
  });

  test('sau dispose, thay đổi mạng không gây lỗi', () async {
    final fake = FakeConnectivityService(online: true);
    final vm = ConnectivityViewModel(fake);
    await Future<void>.delayed(Duration.zero);

    vm.dispose();
    fake.setOnline(false); // không được ném lỗi
    await Future<void>.delayed(Duration.zero);

    await fake.dispose();
  });
}
