import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/ui_breakpoints.dart';
import 'package:flutter/material.dart';

/// Maps user level 1..5 to a multiplicative factor around 1.0.
/// Centered at 3 => 1.0, with gentle steps to preserve readability.
/// 1: 0.9, 2: 0.95, 3: 1.0, 4: 1.1, 5: 1.25
double userLevelToFactor(int level) {
  switch (level) {
    case 1:
      return 0.90;
    case 2:
      return 0.95;
    case 3:
      return 1.00;
    case 4:
      return 1.10;
    case 5:
      return 1.25;
    default:
      return 1.00;
  }
}

/// Computes an effective text scale factor combining device/accessibility scale
/// with the user's preference, and clamps by screen class for legibility.
double effectiveTextScaleFactor(BuildContext context, UiPrefsData prefs) {
  final mq = MediaQuery.of(context);
  final device = mq.textScaler.scale(1.0).clamp(0.8, 2.0);
  final user = userLevelToFactor(prefs.textScaleLevel);
  final raw = (device * user).toDouble();
  // Clamp by screen class to keep within readable standards per device size
  final sc = classifyScreen(mq.size);
  final (minTSF, maxTSF) = switch (sc) {
    ScreenClass.compact => (0.90, 1.30),
    ScreenClass.medium => (0.90, 1.35),
    ScreenClass.wide => (0.90, 1.40),
  };
  return raw.clamp(minTSF, maxTSF);
}
