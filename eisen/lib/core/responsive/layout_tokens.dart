import 'package:flutter/widgets.dart';

/// Layout tokens (spacing, radius, paddings, touch targets) used across the app.
/// Follow 8pt grid and WCAG touch targets.
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

class AppTouch {
  /// Minimum interactive size recommended by Material for touch.
  static const Size minTarget = Size(48, 48);

  /// Larger targets for desktop can be slightly smaller, but we keep 40+.
  static const Size minTargetDesktop = Size(40, 40);
}
