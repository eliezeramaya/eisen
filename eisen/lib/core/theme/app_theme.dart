import 'dart:ui';

import 'package:flutter/material.dart';
import 'typography.dart';

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
            primary: Color(0xFF9CC6FF),
            secondary: Color(0xFFB3E5C5),
            surface: Color(0xFF111318),
            background: Color(0xFF0D0F13),
          )
        : const ColorScheme.light(
            // Higher-contrast light palette
            primary: Color(0xFF0B57D0), // deep blue
            secondary: Color(0xFF006C47), // deep green
            surface: Color(0xFFFFFFFF),
            background: Color(0xFFF5F7FB),
          ),
    useMaterial3: true,
  );

  final tokens = isDark
      ? const GlassTokens(
          glassBg: Color(0xAA141821),
          blur: 12,
          radius: 20,
          q1: Color(0xFFFF6B6B),
          q2: Color(0xFF6BCB77),
          q3: Color(0xFFFFC15E),
          q4: Color(0xFF6BA8FF),
          halo: Color(0x662B63FF),
        )
      : const GlassTokens(
          // More opaque glass for contrast on light backgrounds
          glassBg: Color(0xCCFFFFFF),
          blur: 12,
          radius: 20,
          // Higher-contrast quadrant colors (paired for light bg)
          q1: Color(0xFFD92D20), // red-600
          q2: Color(0xFF12B76A), // green-600
          q3: Color(0xFFF79009), // amber-600
          q4: Color(0xFF2E90FA), // blue-600
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
    scaffoldBackgroundColor: base.colorScheme.surface,
    appBarTheme: AppBarTheme(
      elevation: 0,
  backgroundColor: base.colorScheme.surface.withValues(alpha: isDark ? 0.4 : 0.9),
      foregroundColor: base.colorScheme.onSurface,
    ),
  );
}
