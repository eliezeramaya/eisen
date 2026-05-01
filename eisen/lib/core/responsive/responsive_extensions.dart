import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

extension ResponsiveContext on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  Orientation get orientation => mq.orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  DeviceClass get deviceClass => deviceClassFromContext(this);

  bool get isPhone => deviceClass == DeviceClass.compact;
  bool get isTablet => deviceClass == DeviceClass.medium;
  bool get isDesktop => deviceClass.isExpandedUp;
  bool get isWide => deviceClass.isLarge;
  bool get isTall => screenSize.height > screenSize.width;

  /// Returns a value based on current breakpoint, useful for paddings/fonts.
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return compact;
      case DeviceClass.medium:
        return medium ?? compact;
      case DeviceClass.expanded:
        return expanded ?? medium ?? compact;
      case DeviceClass.large:
        return large ?? expanded ?? medium ?? compact;
    }
  }
}
