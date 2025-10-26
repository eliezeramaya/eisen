import 'dart:ui';

import 'package:flutter/material.dart';
import 'typography.dart';
import 'colors.dart';
import 'minimal_tokens.dart';

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
  if (isDark) {
    // AA-friendly dark palette
    const bg = Color(0xFF0B0F14);
    const surface = Color(0xFF11161C);
    const surface2 = Color(0xFF161C23);
    const onBg = Color(0xFFE6E9EE);
    const onBg2 = Color(0xFFB4BCC8);
    const outline = Color(0x1FFFFFFF); // 12%
    const divider = Color(0x12FFFFFF); // 7%
    const primary = Color(0xFF6AA7FF);
    const primaryHi = Color(0xFF8BB9FF);

    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.black,
      primaryContainer: primaryHi,
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFF9AA8B7),
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF3A4756),
      onSecondaryContainer: onBg,
      surface: surface,
      onSurface: onBg,
      surfaceContainerHighest: surface2,
      surfaceContainerLow: surface,
      surfaceVariant: surface2,
      onSurfaceVariant: onBg2,
      background: bg,
      onBackground: onBg,
      error: Color(0xFFFF7A7A),
      onError: Colors.black,
      outline: outline,
      outlineVariant: Color(0x26FFFFFF),
      shadow: Colors.black,
      scrim: Colors.black,
      tertiary: Color(0xFF66D08F),
      onTertiary: Colors.black,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      dialogBackgroundColor: surface,
      canvasColor: surface,
      dividerColor: divider,
    );

    final tokens = GlassTokens(
      // Lower overlay alpha for better legibility
      glassBg: const Color(0x6B0B0F14), // ~42% of bg
      blur: 12,
      radius: 16,
      q1: EisenColors.q1Dark,
      q2: EisenColors.q2Dark,
      q3: EisenColors.q3Dark,
      q4: EisenColors.q4Dark,
      halo: const Color(0x332E90FA),
    );

    return base.copyWith(
      textTheme: _darkTextTheme(buildTypography(base.textTheme)),
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: onBg),
        titleTextStyle: base.textTheme.titleMedium?.copyWith(color: onBg, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
          side: const BorderSide(color: outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        hintStyle: const TextStyle(color: onBg2),
        labelStyle: const TextStyle(color: onBg),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: outline),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface2,
        selectedColor: primary.withOpacity(.16),
        secondarySelectedColor: primary.withOpacity(.24),
        labelStyle: const TextStyle(color: onBg),
        side: const BorderSide(color: outline),
        shape: StadiumBorder(side: const BorderSide(color: outline)),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1, space: 16),
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      focusColor: primary,
    );
  }

  // Light theme branch (unchanged except tokens/containers)
  const surfaceColor = Color(0xFFFFFFFF);
  const canvasColor = Color(0xFFF9FAFB);
  final colorScheme = const ColorScheme.light(
    primary: EisenColors.q2,
    secondary: EisenColors.q3,
    surface: surfaceColor,
  ).copyWith(surfaceContainerLowest: canvasColor);

  final base = ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    useMaterial3: true,
  );

  const tokens = GlassTokens(
    glassBg: Color(0xCCFFFFFF),
    blur: 12,
    radius: 20,
    q1: EisenColors.q1,
    q2: EisenColors.q2,
    q3: EisenColors.q3,
    q4: EisenColors.q4,
    halo: Color(0x332E90FA),
  );

  return base.copyWith(
    textTheme: buildTypography(base.textTheme),
    extensions: const <ThemeExtension<dynamic>>[tokens],
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.glassBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
      ),
    ),
    scaffoldBackgroundColor: canvasColor,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.85),
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

TextTheme _darkTextTheme(TextTheme t) {
  return t.copyWith(
    bodyLarge: t.bodyLarge?.copyWith(color: const Color(0xFFE6E9EE), height: 1.42),
    bodyMedium: t.bodyMedium?.copyWith(color: const Color(0xFFB4BCC8), height: 1.42, letterSpacing: .1),
    titleMedium: t.titleMedium?.copyWith(color: const Color(0xFFE6E9EE), fontWeight: FontWeight.w600),
    labelLarge: t.labelLarge?.copyWith(color: const Color(0xFFE6E9EE)),
  );
}

/// Returns a flattened, high‑legibility minimal variant of the given theme.
ThemeData asMinimal(ThemeData t) {
  final cs = t.colorScheme;
  final border = (cs.brightness == Brightness.dark)
      ? const Color(0x1FFFFFFF)
      : const Color(0x1F000000);

  final List<ThemeExtension<dynamic>> currentExt =
      t.extensions.values.cast<ThemeExtension<dynamic>>().toList();
  return t.copyWith(
    cardTheme: (t.cardTheme as CardThemeData?)?.copyWith(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border, width: 1),
          ),
        ) ??
        CardThemeData(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border, width: 1),
          ),
        ),
    appBarTheme: t.appBarTheme.copyWith(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: t.colorScheme.surface,
    ),
    inputDecorationTheme: t.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: t.colorScheme.surfaceContainerHighest,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    chipTheme: t.chipTheme.copyWith(
      elevation: 0,
      shadowColor: Colors.transparent,
      side: BorderSide(color: border),
      selectedColor: cs.primary.withValues(alpha: .14),
      backgroundColor: t.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: cs.onSurface),
    ),
    dividerTheme: t.dividerTheme.copyWith(color: border, thickness: 1, space: 16),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: cs.primary.withValues(alpha: .24),
    hoverColor: cs.primary.withValues(alpha: .06),
    extensions: [const MinimalTokens(enabled: true), ...currentExt],
  );
}
