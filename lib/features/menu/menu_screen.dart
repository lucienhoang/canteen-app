import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'menu_item_detail_screen.dart'; //màng hình chi tiết
import 'menu_viewmodel.dart';
import '../auth/logout_button.dart';
import '../cart/cart_screen.dart';

/// Màn hình hiển thị thực đơn (UI Layer).
/// Chỉ đóng vai trò hiển thị trạng thái và chuyển tương tác người dùng cho [MenuViewmodel].
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe (watch) sự thay đổi từ MenuViewmodel
    // Mỗi khi ViewModel gọi notifyListeners(), hàm build này sẽ được chạy lại.
    final vm = context.watch<MenuViewmodel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu căn tin"),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const LogoutButton(),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  /// Hàm dựng giao diện chính dựa trên trạng thái của Viewmodel
  Widget _buildBody(BuildContext context, MenuViewmodel vm) {
    // 1. Trạng thái đnag tải dữ liệu
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Trạng thái gặp lỗi khi tải dữ liệu
    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.error!),
            const SizedBox(height: 8),
            ElevatedButton(
              // Dùng context.read để gọi hàm load(), không đăng ký lắng nghe re-build
              onPressed: () => context.read<MenuViewmodel>().load(),
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    // Định dạng số tiền theo chuẩn Việt Nam
    final priceFormat = NumberFormat.decimalPattern('vi');

    // 3. Trạng thái hiển thị dữ liệu thành công
    return Column(
      children: [
        //Thanh tìm kiếm (TextField)
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm món ăn...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
            // Lắng nghe sự kiện gõ chữ và gọi hàm search bên ViewModel
            onChanged: (value) => context.read<MenuViewmodel>().search(value),
          ),
        ),
        // Danh sách các mục cuộn ngang (Horizontal List)
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Chip "Tất cả" (id = null)
              _chip(context, "Tất cả", null, vm.selectedCategoryId),
              // Tạo các chip cho từng danh mục lấy từ ViewModel
              for (final c in vm.categories)
                _chip(context, c.name, c.id, vm.selectedCategoryId),
            ],
          ),
        ),

        // Danh sách lấy món ăn được lọc theo danh mục (Vertical List)
        Expanded(
          child: ListView.builder(
            itemCount: vm.visibleItems.length,
            itemBuilder: (context, index) {
              final item = vm.visibleItems[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text('${priceFormat.format(item.price)}đ'),
                // Nếu hết hàng thì hiện chữ "Hết hàng" màu đỏ ở cuối card
                trailing: item.isAvailable
                    ? null
                    : const Text(
                        "Hết hàng",
                        style: TextStyle(color: Colors.red),
                      ),
                // Vô hiệu hóa (làm mờ) item nếu hết hàng
                enabled: item.isAvailable,
                // Xử lý sự kiện chọn món: điều hướng sang màn hình chi tiết và truyền dữ liệu (item).
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuItemDetailScreen(item: item),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Widget phu trợ tạo ra nút chọn danh mục (ChoiceChip)
  Widget _chip(BuildContext context, String label, int? id, int? selectedId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: id == selectedId,
        onSelected: (_) => context.read<MenuViewmodel>().selectCategory(id),
      ),
    );
  }
}
