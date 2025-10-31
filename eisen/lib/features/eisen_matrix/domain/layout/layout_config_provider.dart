import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/ui_breakpoints.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'layout_config.dart';

/// Responsive LayoutConfig provider keyed by viewport size.
///
/// Preserves user preferences but applies dynamic topKPerQuadrant overrides
/// based on screen class:
/// - compact (<600px): force 3
/// - medium (600–1279px): use user value (clamped 3–60)
/// - wide (>=1280px): ensure at least 4
final layoutConfigForSizeProvider =
    Provider.autoDispose.family<LayoutConfig, Size>((ref, size) {
  final prefs = ref.watch(uiPrefsProvider);
  final sc = classifyScreen(size);

  final userTopK = prefs.topKPerQuadrant.clamp(3, 60);
  int effectiveTopK;
  switch (sc) {
    case ScreenClass.compact:
      effectiveTopK = 3;
      break;
    case ScreenClass.medium:
      effectiveTopK = userTopK;
      break;
    case ScreenClass.wide:
      effectiveTopK = userTopK < 4 ? 4 : userTopK;
      break;
  }

  return LayoutConfig(
    topKPerQuadrant: effectiveTopK,
    gamma: prefs.gamma,
    minAreaNormalized: prefs.minAreaNormalized,
    quadrantPadding: prefs.quadrantPadding,
  );
});
