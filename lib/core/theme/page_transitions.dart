import 'package:flutter/material.dart';

class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    // Sử dụng curve easeOutCubic theo yêu cầu đề bài
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    // Trượt từ phải (0.08) về vị trí gốc (0)
    final offsetTween = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    );

    // Bọc FadeTransition (Mờ dần) bên ngoài SlideTransition (Trượt)
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: offsetTween.animate(curvedAnimation),
        child: child,
      ),
    );
  }
}