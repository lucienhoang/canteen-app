import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/order_status.dart';
import '../../data/repositories/order_repository.dart';
import 'order_tracking_viewmodel.dart';

/// Các bước hiển thị trên timeline theo đúng thứ tự luồng đơn hàng bình thường.
/// [OrderStatus.cancelled] là nhánh rẽ riêng, không nằm trong timeline này.
const _trackingSteps = [
  OrderStatus.pending,
  OrderStatus.preparing,
  OrderStatus.ready,
  OrderStatus.completed,
];

/// Màn hình theo dõi 1 đơn hàng, hiển thị dạng timeline động.
///
/// Nhận [OrderRepository] qua constructor (Dependency Injection) giúp
/// dễ dàng test với MockOrderRepository hoặc chạy thật với SqliteOrderRepository.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderRepository,
  });

  final int orderId;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          OrderTrackingViewModel(orderRepository: orderRepository)
            ..loadOrder(orderId),
      child: const _OrderTrackingBody(),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  const _OrderTrackingBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderTrackingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Theo dõi đơn hàng"), centerTitle: true),
      body: Builder(
        builder: (context) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.errorMessage != null) {
            return Center(
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final order = vm.order!;

          // Đơn bị hủy -> Hiện Banner báo hủy riêng biệt
          if (order.status == OrderStatus.cancelled) {
            return const _CancelledBanner();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Đơn #${order.id}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _Timeline(currentStatus: order.status),
              const SizedBox(height: 32),
              Text(
                "Giờ lấy hẹn: ${DateFormat('HH:mm dd/MM/yyyy').format(order.pickupTime)}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (order.note != null && order.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Ghi chú: ${order.note}"),
                ),
              const Divider(height: 32),
              ...order.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.menuItemName),
                  trailing: Text('x${item.quantity}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel_outlined, size: 56, color: Colors.red),
          SizedBox(height: 12),
          Text(
            'Đơn hàng đã bị huỷ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timeline dạng chấm tròn nối nhau, animation "nở ra" khi 1 bước được kích hoạt.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.currentStatus});

  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _trackingSteps.indexOf(currentStatus);

    return Column(
      children: List.generate(_trackingSteps.length, (i) {
        final step = _trackingSteps[i];
        final isActive = i <= currentIndex;
        final isLast = i == _trackingSteps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Animation nảy chấm tròn khi bước được kích hoạt
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: isActive ? 1 : 0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Colors.grey.shade300,
                          Theme.of(context).colorScheme.primary,
                          value,
                        ),
                      ),
                      child: value > 0.5
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    );
                  },
                ),
                // Thanh nối dọc giữa các chấm
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 2,
                    height: 40,
                    color: i < currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                step.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? null : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
