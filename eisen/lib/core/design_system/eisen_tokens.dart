import 'package:flutter/material.dart';

/// Core spacing tokens for Eisen.
class EisenSpacing {
  const EisenSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Radius tokens for Eisen components.
class EisenRadius {
  const EisenRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// Elevation tokens for Eisen components.
class EisenElevation {
  const EisenElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
}

/// Color accessors mapped from the app [ColorScheme].
extension EisenColorTokens on ColorScheme {
  Color get eisenPrimary => primary;
  Color get eisenSecondary => secondary;
  Color get eisenSurface => surface;
  Color get eisenSurfaceAlt => surfaceContainerHigh;
  Color get eisenBorderSubtle =>
      outlineVariant.withValues(alpha: 0.5);
  Color get eisenError => error;
}

