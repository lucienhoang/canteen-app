import 'dart:async';

import 'package:canteen_app/core/network/connectivity_service.dart';

/// Bản giả để test: tự điều khiển được trạng thái mạng.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this._online = true});

  bool _online;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  /// Giả lập mạng bật/tắt.
  void setOnline(bool value) {
    _online = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}
