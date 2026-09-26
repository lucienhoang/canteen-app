import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/models/menu_item.dart';
import 'cart_viewmodel.dart';
import '../orders/order_tracking_screen.dart';

/// Màn hình Giỏ hàng - hiển thị danh sách các món đang chọn,
/// cho phép điều chỉnh số lượng, xóa món và thực hiện đặt đơn (Checkout).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu giả lập để kiểm thử giao diện trong giai đoạn phát triển.
    // TODO: Xóa đoạn mock này khi ghép nối nút "Thêm vào giỏ" từ MenuScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartViewModel>();
      if (cart.isEmpty) {
        cart.addItem(
          const MenuItem(id: 1, categoryId: 1, name: "Cơm Sườn", price: 35000),
        );
        cart.addItem(
          const MenuItem(id: 2, categoryId: 2, name: 'Trà đá', price: 5000),
        );
      }
    });
  }

  // Định dạng hiển thị tiền tệ Việt Nam VNĐ
  final _priceFormat = NumberFormat.decimalPattern('vi');
  String _formatPrice(int price) => '${_priceFormat.format(price)}đ';

  /// Xử lý logic khi bấm nút Đặt đơn
  Future<void> _handleCheckout(CartViewModel cart) async {
    final order = await cart.checkout(
      userId: 1, // TODO: Thay thế bằng ID của User đang đăng nhập
      pickupTime: DateTime.now().add(const Duration(minutes: 30)),
    );

    // Kiểm tra Widget còn nằm trong cây Widget tree trước khi thao tác với BuildContext
    if (!mounted) return;

    if (order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đặt đơn thành công! Mã đơn ${order.id}")),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: order.id!,
            orderRepository: SqliteOrderRepository(),
          ),
        ),
      );
    } else if (cart.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(cart.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi trạng thái của CartViewModel
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: cart.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  title: Text(item.menuItemName),
                  subtitle: Text(_formatPrice(item.priceAtOrder)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút giảm số lượng
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => context
                            .read<CartViewModel>()
                            .updateQuantity(item.menuItemId, item.quantity - 1),
                      ),
                      // Hiển thị số lượng
                      Text('${item.quantity}'),
                      // Nút tăng số lượng
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => context
                            .read<CartViewModel>()
                            .updateQuantity(item.menuItemId, item.quantity + 1),
                      ),
                      // Nút xóa món khỏi giỏ
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context
                            .read<CartViewModel>()
                            .removeItem(item.menuItemId),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dòng hiển thị Tổng cộng thanh toán
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tổng cộng",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatPrice(cart.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nút bấm Đặt đơn
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (cart.isEmpty || cart.isSubmitting)
                    ? null
                    : () => _handleCheckout(cart),
                child: cart.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Đặt đơn"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
