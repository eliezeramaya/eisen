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
  static Color stroke(ColorScheme cs) => cs.outlineVariant.withOpacity(borderOpacity);
}

