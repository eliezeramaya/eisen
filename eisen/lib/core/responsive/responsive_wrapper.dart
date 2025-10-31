import 'package:flutter/widgets.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';

class ResponsiveData {
  ResponsiveData(this.bp, this.width);
  final BreakpointSize bp;
  final double width;

  bool get isMobile => bp == BreakpointSize.xs;
  bool get isTablet => bp == BreakpointSize.sm || bp == BreakpointSize.md;
  bool get isDesktop => bp == BreakpointSize.lg || bp == BreakpointSize.xl;
  bool get isUltraWide => bp == BreakpointSize.xl && width >= AppBreakpoints.xl;

  double get spacingScale => switch (bp) {
        BreakpointSize.xs => 1.0,
        BreakpointSize.sm => 1.0,
        BreakpointSize.md => 1.1,
        BreakpointSize.lg => 1.15,
        BreakpointSize.xl => 1.2,
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
    return ResponsiveData(breakpointOf(w), w);
  }

  @override
  bool updateShouldNotify(covariant Responsive oldWidget) =>
      oldWidget.data.bp != data.bp || oldWidget.data.width != data.width;
}

