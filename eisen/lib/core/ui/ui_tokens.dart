import 'package:flutter/material.dart';

class UiTokens {
  // Margins / gaps (keep current visual spacing)
  static const double tileMargin = 4; // painter gap between tiles
  static const double tileRadius = 12; // uniform corner radius
  static const double tileStroke = 1; // 1dp border
  static const double painterDeflateAA = 1; // minimal deflate for AA

  // Recommended outline opacity (tune 0.24–0.32 if needed)
  static double borderOpacity = .28;

  // Material 3 surface/outline helpers
  static Color fill(ColorScheme cs) => cs.surfaceContainerHigh;
  static Color stroke(ColorScheme cs) =>
      cs.outlineVariant.withValues(alpha: borderOpacity);

  // Gantt mode tokens
  static const double laneHeight = 64;
  static const double laneGap = 12;
  static const double barRadius = 14;
  static const double barStroke = 1;
  static const double headerHeight = 56;
  static const double pxPerDayDefault = 32; // intermediate scale
  // Zoom clamps for Gantt (Stage 4)
  static const double pxPerDayMin = 18;
  static const double pxPerDayMax = 64;

  static Color bgDark = const Color(0xFF0E0F11);
  static Color panelDark = const Color(0xFF141618);
  static Color divider = Colors.white.withValues(alpha: 0.08);
  static Color now = const Color(0xFF17D3B0);
}
