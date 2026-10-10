import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';
import 'staff_viewmodel.dart';
import '../auth/logout_button.dart';

/// Màn hình nhân viên căn tin: xem đơn mới, cập nhật trạng thái đơn.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key, required this.orderRepository});

  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          StaffViewModel(orderRepository: orderRepository)..startWatching(),
      child: const _StaffBody(),
    );
  }
}

class _StaffBody extends StatelessWidget {
  const _StaffBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffViewModel>();
    final priceFormat = NumberFormat.decimalPattern("vi");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn hàng - Nhân viên"),
        actions: const [LogoutButton()],
      ),
      body: Builder(
        builder: (context) {
          if (vm.isLoading && vm.activeOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.activeOrders.isEmpty) {
            return const Center(child: Text("Khong có đơn nào cần xử lý"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.activeOrders.length,
            itemBuilder: (context, index) {
              final order = vm.activeOrders[index];
              return _OrderCard(
                order: order,
                priceFormat: priceFormat,
                onChangeStatus: (status) =>
                    context.read<StaffViewModel>().changeStatus(order, status),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.priceFormat,
    required this.onChangeStatus,
  });

  final Order order;
  final NumberFormat priceFormat;
  final void Function(OrderStatus) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    // Chỉ hiện nút cho các bước hợp lệ theo canChangeTO,tự động khớp
    // với bảng _transitions trong OrderStatus.
    final nextOption = OrderStatus.values
        .where((s) => order.status.canChangeTo(s))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Đơn #${order.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(label: Text(order.status.label)),
              ],
            ),
            if (order.userName.isNotEmpty || order.userMssv.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${order.userName} · ${order.userMssv}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Text("${item.menuItemName} x ${item.quantity}"),
            ),
            const SizedBox(height: 4),
            Text("Tổng: ${priceFormat.format(order.totalAmount)}đ"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: nextOption.map((status) {
                final isCancel = status == OrderStatus.cancelled;
                return OutlinedButton(
                  style: isCancel
                      ? OutlinedButton.styleFrom(foregroundColor: Colors.red)
                      : null,
                  onPressed: () => onChangeStatus(status),
                  child: Text(isCancel ? "Hủy Đơn" : "Chuyển: ${status.label}"),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
