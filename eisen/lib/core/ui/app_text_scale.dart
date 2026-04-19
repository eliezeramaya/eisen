import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/text_scaling.dart';
import 'package:flutter/material.dart';

/// Centralized text scale helper for Eisen.
///
/// Encapsulates device scale, user preference level, clamping rules and
/// special-case thresholds for adaptive layout.
class AppTextScale {
  AppTextScale._();

  // Device/system text scale factor from MediaQuery, lightly clamped.
  static double device(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 2.0);

  // User scale factor from preference level (1..5).
  static double userFromLevel(int level) => userLevelToFactor(level);

  // Combined raw (device * user) — BEFORE global clamping.
  static double combinedRaw(BuildContext context, UiPrefsData prefs) =>
      device(context) * userFromLevel(prefs.textScaleLevel);

  // Combined with clamping by screen class (preferred for general UI).
  static double of(BuildContext context, UiPrefsData prefs) =>
      effectiveTextScaleFactor(context, prefs);

  // Treemap labels prefer a tighter clamp for readability inside tiles.
  static double forTreemap(BuildContext context, UiPrefsData prefs) =>
      of(context, prefs).clamp(0.95, 1.20);

  // Extreme threshold for adaptive tweaks (extra spacing, larger hit areas).
  // Uses raw (pre-clamp) so it reflects user intent even if UI clamping applies.
  static bool isExtreme(BuildContext context, UiPrefsData prefs) =>
      combinedRaw(context, prefs) > 1.5;

  // Convenience: builds a MediaQuery with our app scale applied.
  static MediaQueryData mediaWithAppScale(
    BuildContext context,
    UiPrefsData prefs,
  ) {
    final mq = MediaQuery.of(context);
    return mq.copyWith(textScaler: TextScaler.linear(of(context, prefs)));
  }
}
