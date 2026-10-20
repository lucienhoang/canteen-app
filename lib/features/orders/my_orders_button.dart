import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/order_repository.dart';
import '../auth/auth_viewmodel.dart';
import 'my_orders_viewmodel.dart';
import 'order_tracking_screen.dart';
import '../../data/models/order_status.dart';

class MyOrdersButton extends StatelessWidget {
  const MyOrdersButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy userId và orderRepository từ context
    final user = context.read<AuthViewModel>().currentUser;
    final orderRepo = context.read<OrderRepository>();

    // Nếu chưa đăng nhập thì không hiện nút
    if (user == null) return const SizedBox.shrink();

    // Bọc giao diện nút bằng Provider để cung cấp MyOrdersViewModel
    return ChangeNotifierProvider(
      create: (_) => MyOrdersViewModel(
        userId: user.id,
        orderRepository: orderRepo,
      ),
      child: const _MyOrdersButtonView(),
    );
  }
}

class _MyOrdersButtonView extends StatelessWidget {
  const _MyOrdersButtonView();

  void _handleTap(BuildContext context, MyOrdersViewModel vm) {
    final orders = vm.activeOrders;

    if (orders.isEmpty) {
      // Trường hợp 0 đơn
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa có đơn nào đang xử lý')),
      );
    } else if (orders.length == 1) {
      // Trường hợp 1 đơn -> Mở thẳng
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: orders.first.id!,
            orderRepository: context.read<OrderRepository>(),
          ),
        ),
      );
    } else {
      // Trường hợp >= 2 đơn -> Hiện BottomSheet
      showModalBottomSheet(
        context: context,
        builder: (bsContext) {
          return ListView.builder(
            shrinkWrap: true, // Ôm gọn theo nội dung
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text('Đơn #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Trạng thái: ${order.status.label} - Giờ lấy: ${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(bsContext); // Đóng BottomSheet trước
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(
                        orderId: order.id!,
                        orderRepository: context.read<OrderRepository>(),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi của danh sách đơn hàng
    final vm = context.watch<MyOrdersViewModel>();
    final count = vm.activeOrders.length;

    return IconButton(
      tooltip: 'Đơn của tôi',
      onPressed: () => _handleTap(context, vm),
      icon: Badge(
        isLabelVisible: count > 0, // Chỉ hiện Badge nếu có > 0 đơn
        label: Text(count.toString()),
        child: const Icon(Icons.receipt_long),
      ),
    );
  }
}