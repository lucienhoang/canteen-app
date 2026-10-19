import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/responsive_center.dart';
import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';
import 'staff_viewmodel.dart';
import '../auth/logout_button.dart';
import '../../core/widgets/skeleton_list.dart';

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

/// Số cột thẻ đơn theo bề rộng khả dụng: điện thoại 1, tablet 2, màn rộng 3.
int staffColumnsFor(double width) {
  if (width >= 900) return 3;
  if (width >= 600) return 2;
  return 1;
}

class _StaffBody extends StatelessWidget {
  const _StaffBody();

  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffViewModel>();
    final priceFormat = NumberFormat.decimalPattern("vi");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn hàng - Nhân viên"),
        actions: const [LogoutButton()],
      ),
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: Column(
          children: [
            // Dải báo lỗi (mất mạng, thiếu quyền...) hiện phía trên danh sách
            if (vm.errorMessage != null)
              _ErrorBanner(message: vm.errorMessage!),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (vm.isLoading && vm.activeOrders.isEmpty) {
                    // Dùng biến thể cards dành riêng cho màn hình này
                    return const SkeletonList.cards();
                  }
                  if (vm.activeOrders.isEmpty) {
                    return const Center(
                      child: Text("Không có đơn nào cần xử lý"),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = staffColumnsFor(constraints.maxWidth);
                      // Trừ padding hai bên và khoảng cách giữa các cột.
                      final cardWidth =
                          (constraints.maxWidth -
                              _spacing * 2 -
                              _spacing * (columns - 1)) /
                          columns;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(_spacing),
                        // Wrap (không phải GridView) vì mỗi thẻ cao khác nhau
                        // tùy số món trong đơn.
                        child: Wrap(
                          spacing: _spacing,
                          runSpacing: _spacing,
                          children: [
                            for (final order in vm.activeOrders)
                              SizedBox(
                                width: cardWidth,
                                child: _OrderCard(
                                  order: order,
                                  priceFormat: priceFormat,
                                  onChangeStatus: (status) => context
                                      .read<StaffViewModel>()
                                      .changeStatus(order, status),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải thông báo lỗi màu đỏ nhạt ở đầu màn hình.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
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
      // Khoảng cách giữa các thẻ do Wrap lo (spacing/runSpacing).
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expanded + ellipsis: mã đơn dài không đẩy Chip ra ngoài thẻ hẹp.
                Expanded(
                  child: Text(
                    "Đơn #${order.id}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
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

            const Divider(height: 16), // Thêm đường kẻ phân cách cho đẹp

            // --- PHẦN THÊM MỚI: GIỜ LẤY ---
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  "Giờ lấy: ${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            // --- PHẦN THÊM MỚI: GHI CHÚ ---
            if (order.note != null && order.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Ghi chú: ${order.note}",
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
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
                      ? OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
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
