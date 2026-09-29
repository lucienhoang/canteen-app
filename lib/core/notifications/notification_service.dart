import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';

/// Quản lý thông báo cục bộ cho toàn app (singleton).
/// Dùng để báo cho khách khi trạng thái đơn hàng thay đổi.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Khởi tạo plugin — gọi 1 lần lúc app khởi động (main.dart).
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Xin quyền gửi thông báo — bắt buộc trên Android 13+ (API 33+).
  /// Gọi sau initialize(), trước khi cần gửi thông báo đầu tiên.
  Future<void> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Nội dung thông báo theo trạng thái đơn — tách riêng để test được
  /// mà không cần gọi plugin thật.
  static String buildTitle(Order order) => 'Đơn #${order.id}';

  static String buildBody(Order order) {
    switch (order.status) {
      case OrderStatus.preparing:
        return 'Đơn hàng của bạn đang được chuẩn bị.';
      case OrderStatus.ready:
        return 'Đơn hàng đã sẵn sàng, mời bạn tới lấy!';
      case OrderStatus.completed:
        return 'Đơn hàng đã hoàn tất. Cảm ơn bạn đã đặt món!';
      case OrderStatus.cancelled:
        return 'Đơn hàng đã bị huỷ.';
      case OrderStatus.pending:
        return 'Đơn hàng của bạn đang chờ xử lý.';
    }
  }

  /// Gửi thông báo khi trạng thái 1 đơn hàng thay đổi.
  Future<void> showOrderStatusNotification(Order order) async {
    const androidDetails = AndroidNotificationDetails(
      'order_status_channel',
      'Trạng thái đơn hàng',
      channelDescription: 'Thông báo khi đơn hàng đổi trạng thái',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      order.id!, // dùng orderId làm notification id — mỗi đơn 1 thông báo riêng, đơn sau đè đơn trước nếu cùng id
      buildTitle(order),
      buildBody(order),
      details,
    );
  }
}
