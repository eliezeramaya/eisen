import 'package:flutter/widgets.dart';

/// App-wide breakpoint tokens.
///
/// Widths are in logical pixels.
class AppBreakpoints {
  static const double compact = 0;
  static const double medium = 600;
  static const double expanded = 905;
  static const double large = 1240;
}

/// Semantic categories for responsive decisions.
enum DeviceClass {
  compact,
  medium,
  expanded,
  large,
}

extension DeviceClassX on DeviceClass {
  bool get isCompact => this == DeviceClass.compact;
  bool get isMedium => this == DeviceClass.medium;
  bool get isExpanded => this == DeviceClass.expanded;
  bool get isLarge => this == DeviceClass.large;

  bool get isMediumUp => index >= DeviceClass.medium.index;
  bool get isExpandedUp => index >= DeviceClass.expanded.index;
  bool get isLargeUp => index >= DeviceClass.large.index;
}

/// Returns the [DeviceClass] for a given width.
DeviceClass deviceClassOf(double width) {
  if (width < AppBreakpoints.medium) return DeviceClass.compact;
  if (width < AppBreakpoints.expanded) return DeviceClass.medium;
  if (width < AppBreakpoints.large) return DeviceClass.expanded;
  return DeviceClass.large;
}

/// Compute device class from current [BuildContext].
DeviceClass deviceClassFromContext(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return deviceClassOf(w);
}
