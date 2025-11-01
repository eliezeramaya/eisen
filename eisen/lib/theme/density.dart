import 'package:flutter/material.dart';

/// Density presets for desktop-focused layouts.
enum DensityPreset { comfy, compact, ultra }

/// Global spacing tokens to avoid magic numbers in paddings/margins.
class SpacingTokens extends ThemeExtension<SpacingTokens> {
  final double insetXs, insetSm, insetMd;
  const SpacingTokens({
    required this.insetXs,
    required this.insetSm,
    required this.insetMd,
  });

  @override
  SpacingTokens copyWith({double? insetXs, double? insetSm, double? insetMd}) =>
      SpacingTokens(
        insetXs: insetXs ?? this.insetXs,
        insetSm: insetSm ?? this.insetSm,
        insetMd: insetMd ?? this.insetMd,
      );

  @override
  ThemeExtension<SpacingTokens> lerp(
    ThemeExtension<SpacingTokens>? other,
    double t,
  ) =>
      this; // no-op (discrete tokens)
}

/// Standalone theme for density preset (not used directly by app theme).
/// Provided to satisfy API requirements and potential previews.
ThemeData buildTheme(DensityPreset preset) {
  final isCompact =
      preset == DensityPreset.compact || preset == DensityPreset.ultra;
  final bodySize =
      preset == DensityPreset.ultra ? 12.0 : (isCompact ? 12.5 : 14.0);
  return ThemeData(
    useMaterial3: true,
    visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: bodySize, height: 1.15),
      labelMedium: TextStyle(fontSize: bodySize - 1, height: 1.05),
      titleMedium: TextStyle(fontSize: bodySize + 1, height: 1.1),
    ),
    extensions: <ThemeExtension<dynamic>>[
      SpacingTokens(
        insetXs: isCompact ? 2 : 4,
        insetSm: isCompact ? 4 : 8,
        insetMd: isCompact ? 6 : 12,
      ),
    ],
  );
}

/// Applies density adjustments and spacing tokens on top of an existing theme.
ThemeData applyDensity(ThemeData base, DensityPreset preset) {
  final isCompact =
      preset == DensityPreset.compact || preset == DensityPreset.ultra;
  final bodySize =
      preset == DensityPreset.ultra ? 12.0 : (isCompact ? 12.5 : 14.0);

  // Preserve current extensions and append/override spacing tokens
  final currentExt =
      base.extensions.values.cast<ThemeExtension<dynamic>>().toList();
  // Remove any previous SpacingTokens to avoid duplicates
  currentExt.removeWhere((e) => e is SpacingTokens);

  return base.copyWith(
    visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
    textTheme: base.textTheme.copyWith(
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(fontSize: bodySize, height: 1.15),
      labelMedium: base.textTheme.labelMedium
          ?.copyWith(fontSize: bodySize - 1, height: 1.05),
      titleMedium: base.textTheme.titleMedium
          ?.copyWith(fontSize: bodySize + 1, height: 1.1),
    ),
    extensions: [
      ...currentExt,
      SpacingTokens(
        insetXs: isCompact ? 2 : 4,
        insetSm: isCompact ? 4 : 8,
        insetMd: isCompact ? 6 : 12,
      ),
    ],
  );
}
