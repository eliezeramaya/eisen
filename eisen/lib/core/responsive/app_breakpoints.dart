import 'package:flutter/widgets.dart';

/// App-wide breakpoint tokens inspired by Material 3 and common web breakpoints.
///
/// Widths are in logical pixels.
class AppBreakpoints {
  static const double xs = 0; // phones portrait
  static const double sm = 600; // phones landscape / small tablets
  static const double md = 905; // medium tablets
  static const double lg = 1240; // desktops small
  static const double xl = 1440; // large desktops
}

/// Semantic categories for responsive decisions.
enum BreakpointSize { xs, sm, md, lg, xl }

/// Returns the [BreakpointSize] for a given width.
BreakpointSize breakpointOf(double width) {
  if (width < AppBreakpoints.sm) return BreakpointSize.xs;
  if (width < AppBreakpoints.md) return BreakpointSize.sm;
  if (width < AppBreakpoints.lg) return BreakpointSize.md;
  if (width < AppBreakpoints.xl) return BreakpointSize.lg;
  return BreakpointSize.xl;
}

/// Compute breakpoint from current [BuildContext].
BreakpointSize breakpointFromContext(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return breakpointOf(w);
}
