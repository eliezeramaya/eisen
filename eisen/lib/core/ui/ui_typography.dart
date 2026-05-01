import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:flutter/widgets.dart';

/// Responsive typography helpers for treemap tiles
/// Returns optimal font sizes based on viewport dimensions

double titleFontSize(Size s) {
  if (s.width < 360) return 12;
  if (s.width < 412) return 13;
  if (s.width < AppBreakpoints.medium) return 14;
  if (s.width < 840) return 15;
  return 16; // desktop/tablet
}

double metaFontSize(Size s) {
  if (s.width < 360) return 10;
  if (s.width < 412) return 11;
  if (s.width < AppBreakpoints.medium) return 12;
  return 13;
}
