import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/menu_item.dart';
import 'package:provider/provider.dart';
import '../cart/cart_viewmodel.dart';

/// Màn hình hiển thị chi tiết của một món ăn trong thực đơn.
///
/// Nhận vào [MenuItem] từ màn hình danh sách và hiển thị đầy đủ
/// thông tin: tên món, giá tiền và trạng thái còn/hết hàng.
class MenuItemDetailScreen extends StatelessWidget {
  /// Dữ liệu món ăn được truyền từ màn hình danh sách
  final MenuItem item;

  const MenuItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.decimalPattern('vi');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết món'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị thông tin cơ bản: Tên món và Giá tiền
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              '${priceFormat.format(item.price)}đ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Khối hiển thị trạng thái kho (Còn hàng / Hết hàng) kèm icon tương ứng
            Row(
              children: [
                Icon(
                  item.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: item.isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  item.isAvailable ? 'Còn hàng' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: item.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // NÚT THÊM VÀO GIỎ HÀNG.
      // Thanh công cụ dưới cùng chứa nút "Thêm vào giỏ"
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            // Tự động disable nút nếu món hết hàng (truyền null vào onPressed)
            onPressed: item.isAvailable
                ? () {
              // Gọi hàm addItem từ CartViewModel
              context.read<CartViewModel>().addItem(item);

              // Hiển thị thông báo (SnackBar)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm ${item.name} vào giỏ'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(item.isAvailable ? 'Thêm vào giỏ' : 'Hết hàng'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}