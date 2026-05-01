import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

class ResponsiveData {
  ResponsiveData(this.deviceClass, this.width);
  final DeviceClass deviceClass;
  final double width;

  bool get isMobile => deviceClass.isCompact;
  bool get isTablet => deviceClass.isMedium;
  bool get isDesktop => deviceClass.isExpandedUp;
  bool get isUltraWide => width >= _ultraWideWidth;

  double get spacingScale => switch (deviceClass) {
        DeviceClass.compact => 1.0,
        DeviceClass.medium => 1.0,
        DeviceClass.expanded => 1.1,
        DeviceClass.large => 1.15,
      };

  double get paddingScale => spacingScale;
}

/// Inherited provider for responsive data. Optional — if not present,
/// `Responsive.of(context)` computes from MediaQuery.
class Responsive extends InheritedWidget {
  const Responsive({super.key, required this.data, required super.child});
  final ResponsiveData data;

  static ResponsiveData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<Responsive>();
    if (inherited != null) return inherited.data;
    final w = MediaQuery.sizeOf(context).width;
    return ResponsiveData(deviceClassOf(w), w);
  }

  @override
  bool updateShouldNotify(covariant Responsive oldWidget) =>
      oldWidget.data.deviceClass != data.deviceClass ||
      oldWidget.data.width != data.width;
}

const double _ultraWideWidth = 1600;
