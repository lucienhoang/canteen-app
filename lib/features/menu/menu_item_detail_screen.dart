import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/menu_item.dart';

/// Màn hình hiển thị chi tiết của một món ăn trong thực đơn.
///
/// Nhận vào [MenuItem] từ màn hình danh sách và hiển thị đầy đủ
/// thông tin: tên món, giá tiền
/// và trạng thái còn hàng / hết hàng.
class MenuItemDetailScreen extends StatelessWidget {
  /// Món ăn cần hiển thị chi tiết, được truyền từ màn hình trước đó.
  final MenuItem item;

  const MenuItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Định dạng số theo chuẩn Việt Nam
    final priceFormat = NumberFormat.decimalPattern('vi');

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết món')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên món ăn
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Giá tiền, đã format và thêm chữ "đ" vào cuối
            Text(
              '${priceFormat.format(item.price)}đ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Trạng thái còn hàng / hết hàng, kèm icon và màu tương ứng
            Row(
              children: [
                Icon(item.isAvailable ? Icons.check_circle : Icons.cancel),
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
    );
  }
}
