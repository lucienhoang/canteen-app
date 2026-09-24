import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/menu_repository.dart';
import 'features/menu/menu_screen.dart';
import 'features/menu/menu_viewmodel.dart';

import 'data/repositories/order_repository.dart';
import 'features/cart/cart_viewmodel.dart';

// import 'features/cart/cart_screen.dart';

void main() {
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MenuViewmodel(MockMenuRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartViewModel(orderRepository: MockOrderRepository()),
        ),
      ],

      child: MaterialApp(
        title: 'Căn tin',
        theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
        home: const MenuScreen(),
      ),
    );
  }
}
