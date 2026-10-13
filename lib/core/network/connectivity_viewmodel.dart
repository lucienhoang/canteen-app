import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

/// Giữ trạng thái mạng cho giao diện. Màn hình chỉ cần đọc [isOnline].
class ConnectivityViewModel extends ChangeNotifier {
  ConnectivityViewModel(this._service) {
    _subscription = _service.onlineChanges.listen(_update);
    // Kiểm tra trạng thái thật ngay lúc khởi tạo.
    unawaited(_service.isOnline().then(_update));
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;
  bool _disposed = false;

  // Mặc định "có mạng" để lúc app vừa mở không nháy dải đỏ oan;
  // vài mili giây sau sẽ được cập nhật theo trạng thái thật.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void _update(bool value) {
    if (_disposed || value == _isOnline) return;
    _isOnline = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
