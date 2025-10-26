import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'layout_config.dart';
import 'package:eisen/core/services/ui_prefs.dart';

final layoutConfigProvider = Provider<LayoutConfig>((ref) {
  final prefs = ref.watch(uiPrefsProvider);
  return LayoutConfig(
    topKPerQuadrant: prefs.topKPerQuadrant,
    minAreaNormalized: prefs.minAreaNormalized,
    gamma: prefs.gamma,
    quadrantPadding: prefs.quadrantPadding,
  );
});
