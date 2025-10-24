import 'dart:ui';

import 'package:flutter/material.dart';
import 'typography.dart';
import 'colors.dart';

@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  final Color glassBg;
  final double blur;
  final double radius;
  final Color q1;
  final Color q2;
  final Color q3;
  final Color q4;
  final Color halo;

  const GlassTokens({
    required this.glassBg,
    required this.blur,
    required this.radius,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.halo,
  });

  @override
  GlassTokens copyWith({
    Color? glassBg,
    double? blur,
    double? radius,
    Color? q1,
    Color? q2,
    Color? q3,
    Color? q4,
    Color? halo,
  }) {
    return GlassTokens(
      glassBg: glassBg ?? this.glassBg,
      blur: blur ?? this.blur,
      radius: radius ?? this.radius,
      q1: q1 ?? this.q1,
      q2: q2 ?? this.q2,
      q3: q3 ?? this.q3,
      q4: q4 ?? this.q4,
      halo: halo ?? this.halo,
    );
  }

  @override
  ThemeExtension<GlassTokens> lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      blur: lerpDouble(blur, other.blur, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
      q1: Color.lerp(q1, other.q1, t)!,
      q2: Color.lerp(q2, other.q2, t)!,
      q3: Color.lerp(q3, other.q3, t)!,
      q4: Color.lerp(q4, other.q4, t)!,
      halo: Color.lerp(halo, other.halo, t)!,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    brightness: brightness,
    colorScheme: isDark
        ? const ColorScheme.dark(
            primary: EisenColors.q2Dark,
            secondary: EisenColors.q3Dark,
            surface: Color(0xFF1E293B), // card
            background: Color(0xFF0F172A), // canvas
          )
        : const ColorScheme.light(
            // Emotional palette tuned for light mode
            primary: EisenColors.q2,
            secondary: EisenColors.q3,
            surface: Color(0xFFFFFFFF),
            background: Color(0xFFF9FAFB),
          ),
    useMaterial3: true,
  );

  final tokens = isDark
      ? const GlassTokens(
          glassBg: Color(0x66151A23),
          blur: 12,
          radius: 20,
          q1: EisenColors.q1Dark,
          q2: EisenColors.q2Dark,
          q3: EisenColors.q3Dark,
          q4: EisenColors.q4Dark,
          halo: Color(0x662E90FA),
        )
      : const GlassTokens(
          // More opaque glass for contrast on light backgrounds
          glassBg: Color(0xCCFFFFFF),
          blur: 12,
          radius: 20,
          // Emotional palette mapped to quadrants
          q1: EisenColors.q1,
          q2: EisenColors.q2,
          q3: EisenColors.q3,
          q4: EisenColors.q4,
          halo: Color(0x332E90FA),
        );

  return base.copyWith(
    textTheme: buildTypography(base.textTheme),
    extensions: <ThemeExtension<dynamic>>[tokens],
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.glassBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        side: BorderSide(
      color: isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
    ),
    scaffoldBackgroundColor: base.colorScheme.background,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: base.colorScheme.surface.withValues(alpha: isDark ? 0.35 : 0.85),
      foregroundColor: base.colorScheme.onSurface,
    ),
  );
}
