import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'layout_config.dart';
import 'treemap_density_resolver.dart';

final layoutConfigProvider = Provider<LayoutConfig>((ref) {
  final prefs = ref.watch(uiPrefsProvider);
  final resolved = TreemapDensityResolver.resolve(
    prefs: prefs,
    screenSize: TreemapDensityResolver.fallbackScreenSize,
  );
  return resolved.layoutConfig;
});
