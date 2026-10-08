import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_viewmodel.dart';
import 'auth_viewmodel.dart';

/// Nút đăng xuất cho AppBar. Xóa giỏ hàng trước để người sau không thấy giỏ của người trước.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Đăng xuất',
      icon: const Icon(Icons.logout),
      onPressed: () {
        final cart = context.read<CartViewModel>();
        final auth = context.read<AuthViewModel>();
        cart.clear();
        auth.signOut();
      },
    );
  }
}
