import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, Settings;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'core/notifications/notification_service.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firestore_order_repository.dart';
import 'data/repositories/menu_repository.dart';
import 'data/repositories/order_repository.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/cart/cart_viewmodel.dart';
import 'features/menu/menu_screen.dart';
import 'features/menu/menu_viewmodel.dart';
import 'features/staff/staff_screen.dart';

import 'features/orders/order_notification_host.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase OK: ${Firebase.app().options.projectId}');

  // Bật cache offline của Firestore: dữ liệu đã tải vẫn hiện được khi mất mạng.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

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
        // Một repository đơn hàng DÙNG CHUNG cho cả app (giỏ hàng, màn nhân viên,
        // màn theo dõi). Phải đứng TRƯỚC CartViewModel vì CartViewModel đọc nó.
        Provider<OrderRepository>(create: (_) => FirestoreOrderRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              CartViewModel(orderRepository: context.read<OrderRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Căn tin',
        theme: AppTheme.light(),
        home: AuthGate(
          studentHome: const OrderNotificationHost(child: MenuScreen()),
          staffHome: Builder(
            builder: (context) =>
                StaffScreen(orderRepository: context.read<OrderRepository>()),
          ),
        ),
      ),
    );
  }
}
