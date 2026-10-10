import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'core/notifications/notification_service.dart';

import 'data/repositories/menu_repository.dart';
import 'data/repositories/order_repository.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/cart/cart_viewmodel.dart';
import 'features/menu/menu_screen.dart';
import 'features/menu/menu_viewmodel.dart';
import 'features/staff/staff_screen.dart';
import 'data/repositories/firebase_auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase OK: ${Firebase.app().options.projectId}');

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermission();
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthViewModel(FirebaseAuthRepository())..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => MenuViewmodel(MockMenuRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CartViewModel(orderRepository: SqliteOrderRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'Căn tin',
        theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
        home: AuthGate(
          studentHome: const MenuScreen(),
          staffHome: StaffScreen(orderRepository: SqliteOrderRepository()),
        ),
      ),
    );
  }
}
