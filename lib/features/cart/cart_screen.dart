import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/responsive_center.dart';
import '../../data/repositories/order_repository.dart';
import 'cart_viewmodel.dart';
import '../orders/order_tracking_screen.dart';
import '../auth/auth_viewmodel.dart';
import 'cart_validators.dart';

/// Màn hình Giỏ hàng - hiển thị danh sách các món đang chọn,
/// cho phép điều chỉnh số lượng, xóa món và thực hiện đặt đơn (Checkout).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.orderRepository});

  /// Repository dùng cho màn theo dõi đơn sau khi đặt.
  /// Để trống thì lấy repository dùng chung từ Provider; test truyền Mock vào.
  final OrderRepository? orderRepository;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Định dạng hiển thị tiền tệ Việt Nam VNĐ
  final _priceFormat = NumberFormat.decimalPattern('vi');
  String _formatPrice(int price) => '${_priceFormat.format(price)}đ';

  // Biến lưu thông báo lỗi nếu chọn sai giờ
  DateTime _pickupTime = DateTime.now().add(const Duration(minutes: 30));
  final TextEditingController _noteController = TextEditingController();
  String? _timeError;
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

// Hàm hiển thị hộp thoại chọn giờ
  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupTime),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      setState(() {
        _pickupTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _timeError = null; // Xóa thông báo lỗi khi đổi giờ
      });
    }
  }

  // Giao diện hiển thị Giờ lấy và Ghi chú
  Widget _buildCheckoutInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thông tin nhận món", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Giờ lấy (Hôm nay)"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_pickupTime.hour.toString().padLeft(2, '0')}:${_pickupTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 4),
                  Text(_timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ]
              ],
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selectTime(context),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: "Ghi chú (không bắt buộc)",
              hintText: "Ví dụ: Ăn tại chỗ, lấy thêm muỗng...",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// Xử lý logic khi bấm nút Đặt đơn
  Future<void> _handleCheckout(CartViewModel cart) async {
    // 1. Kiểm tra tính hợp lệ của giờ lấy TRƯỚC khi đặt đơn
    final now = DateTime.now();
    final error = validatePickupTime(_pickupTime, now);

    if (error != null) {
      setState(() {
        _timeError = error; // Hiện lỗi lên màn hình
      });
      return; // Dừng lại, không thực hiện đặt đơn
    }

    // 2. Lấy thông tin user
    final user = context.read<AuthViewModel>().currentUser;
    final orderRepository = widget.orderRepository ?? context.read<OrderRepository>();

    if (user == null) return; // chưa đăng nhập thì không đặt đơn

    // 3. Gọi hàm checkout với dữ liệu thật do người dùng chọn
    final order = await cart.checkout(
      userId: user.id,
      userName: user.name,
      userMssv: user.mssv,
      pickupTime: _pickupTime,
      note: _noteController.text, // Truyền ghi chú vào đây
    );

    // Kiểm tra Widget còn nằm trong cây Widget tree trước khi thao tác với BuildContext
    if (!mounted) return;

    if (order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đặt đơn thành công! Mã đơn ${order.id}")),
      );

      // Chuyển qua màn hình theo dõi trạng thái đơn khi đã đặt thành công
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: order.id!,
            orderRepository: orderRepository,
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
          : ResponsiveCenter(
              child: ListView.builder(
                itemCount: cart.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == cart.items.length) {
                    return _buildCheckoutInfo();
                  }
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
                          onPressed: () =>
                              context.read<CartViewModel>().updateQuantity(
                                item.menuItemId,
                                item.quantity - 1,
                              ),
                        ),
                        // Hiển thị số lượng
                        Text('${item.quantity}'),
                        // Nút tăng số lượng
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              context.read<CartViewModel>().updateQuantity(
                                item.menuItemId,
                                item.quantity + 1,
                              ),
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
            ),
      // SafeArea: tránh thanh cử chỉ / thanh điều hướng của điện thoại đè lên nút.
      bottomNavigationBar: SafeArea(
        child: ResponsiveCenter(
          shrinkHeight: true,
          child: Padding(
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
        ),
      ),
    );
  }
}
