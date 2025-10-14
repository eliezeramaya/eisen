import 'package:flutter/material.dart';

TextTheme buildTypography(TextTheme base) {
  // Keep defaults; in a real app you might load Inter/Manrope via assets.
  return base.copyWith(
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.2),
    labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.1),
  );
}

