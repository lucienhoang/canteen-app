import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../auth/auth_viewmodel.dart';
import 'order_status_watcher.dart';

/// Bọc quanh màn hình gốc của SINH VIÊN. Trong thời gian sinh viên còn đăng nhập,
/// theo dõi đơn của họ và hiện thông báo khi nhân viên đổi trạng thái.
///
/// Vì `AuthGate` chỉ dựng widget này khi sinh viên đang đăng nhập, nên:
/// - đăng nhập xong -> [initState] chạy -> bắt đầu theo dõi;
/// - đăng xuất      -> widget bị gỡ -> [dispose] chạy -> ngừng theo dõi.
class OrderNotificationHost extends StatefulWidget {
  const OrderNotificationHost({
    super.key,
    required this.child,
    this.onStatusChanged,
  });

  final Widget child;

  /// Mặc định gửi thông báo thật. Test truyền hàm giả để không phụ thuộc plugin.
  final Future<void> Function(Order order)? onStatusChanged;

  @override
  State<OrderNotificationHost> createState() => _OrderNotificationHostState();
}

class _OrderNotificationHostState extends State<OrderNotificationHost> {
  OrderStatusWatcher? _watcher;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    _watcher = OrderStatusWatcher(
      orderRepository: context.read<OrderRepository>(),
      onStatusChanged:
          widget.onStatusChanged ??
          NotificationService.instance.showOrderStatusNotification,
    )..start(user.id);
  }

  @override
  void dispose() {
    _watcher?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
