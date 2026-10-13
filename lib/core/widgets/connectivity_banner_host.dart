import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/connectivity_viewmodel.dart';

/// Hiện dải "không có mạng" ở đầu mọi màn hình khi máy offline.
/// Gắn một lần duy nhất qua `MaterialApp.builder`.
class ConnectivityBannerHost extends StatelessWidget {
  const ConnectivityBannerHost({super.key, required this.child});

  static const String offlineMessage =
      'Không có kết nối mạng — chỉ xem được dữ liệu đã lưu.';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityViewModel, bool>(
      (vm) => vm.isOnline,
    );

    return Column(
      children: [
        // AnimatedSize: dải trượt ra/vào mượt thay vì bật tắt đột ngột.
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isOnline
              ? const SizedBox(width: double.infinity)
              : const _OfflineBanner(),
        ),
        Expanded(
          // Khi dải đang hiện, nó đã chiếm phần thanh trạng thái, nên bỏ
          // phần đệm phía trên để các Scaffold bên dưới không chừa lần nữa.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !isOnline,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true, // trình đọc màn hình sẽ đọc to khi dải xuất hiện
      child: Material(
        color: scheme.errorContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 18, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ConnectivityBannerHost.offlineMessage,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
