import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

extension ResponsiveContext on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  Orientation get orientation => mq.orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  BreakpointSize get bp => breakpointFromContext(this);

  bool get isPhone => bp == BreakpointSize.xs || bp == BreakpointSize.sm;
  bool get isTablet => bp == BreakpointSize.md;
  bool get isDesktop => bp == BreakpointSize.lg || bp == BreakpointSize.xl;
  bool get isWide => screenSize.width >= AppBreakpoints.lg;
  bool get isTall => screenSize.height > screenSize.width;

  /// Returns a value based on current breakpoint, useful for paddings/fonts.
  T responsive<T>({required T xs, T? sm, T? md, T? lg, T? xl}) {
    switch (bp) {
      case BreakpointSize.xs:
        return xs;
      case BreakpointSize.sm:
        return sm ?? xs;
      case BreakpointSize.md:
        return md ?? sm ?? xs;
      case BreakpointSize.lg:
        return lg ?? md ?? sm ?? xs;
      case BreakpointSize.xl:
        return xl ?? lg ?? md ?? sm ?? xs;
    }
  }
}
