import 'package:flutter/widgets.dart';

class A11y {
  static const minTouch = Size(44, 44);

  static Widget touchTarget({required Widget child}) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: child,
      );
}

