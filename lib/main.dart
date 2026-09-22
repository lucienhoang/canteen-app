import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/menu_repository.dart';
import 'features/menu/menu_screen.dart';
import 'features/menu/menu_viewmodel.dart';

void main() {
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuViewmodel(MockMenuRepository())..load(),
      child: MaterialApp(
        title: 'Căn tin',
        theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
        home: const MenuScreen(),
      ),
    );
  }
}
