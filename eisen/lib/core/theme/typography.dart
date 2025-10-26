import 'package:flutter/material.dart';

TextTheme buildTypography(TextTheme base) {
  // Prefer modern, clear typography. If a custom font is not bundled, fall back to system.
  final family = base.bodyMedium?.fontFamily;
  return base.copyWith(
    // Quadrant titles
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: base.titleLarge?.color?.withValues(alpha: 0.9),
      fontFamily: family,
    ),
    // Task names
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: base.titleMedium?.color,
      fontFamily: family,
    ),
    // Subtitles / time
    bodySmall: base.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      height: 1.2,
      color: base.bodySmall?.color?.withValues(alpha: 0.7),
      fontFamily: family,
    ),
    // General body
    bodyMedium: base.bodyMedium?.copyWith(height: 1.25),
    labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.1),
  );
}
