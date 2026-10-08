import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_viewmodel.dart';
import 'login_screen.dart';

/// Chọn màn hình gốc theo trạng thái đăng nhập và vai trò.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.studentHome,
    required this.staffHome,
  });

  final Widget studentHome;
  final Widget staffHome;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    switch (auth.status) {
      case AuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return auth.currentUser!.isStaff ? staffHome : studentHome;
    }
  }
}
