import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Giới hạn bề rộng nội dung và căn giữa trên màn rộng (tablet, Chrome).
///
/// Màn hẹp (điện thoại) thì không ảnh hưởng: bề rộng = bề rộng có sẵn.
/// Con luôn nhận chiều rộng CHẶT (tight), nên nút giãn kín hàng vẫn giãn như cũ.
///
/// Đặt [shrinkHeight] = true khi dùng cho thanh dưới cùng
/// (`bottomNavigationBar`), để thanh chỉ cao bằng nội dung thay vì chiếm hết màn.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.shrinkHeight = false,
  });

  final Widget child;
  final double maxWidth;
  final bool shrinkHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: shrinkHeight ? 1 : null,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}
