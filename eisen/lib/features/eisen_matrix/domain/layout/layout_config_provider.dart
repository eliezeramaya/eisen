import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'layout_config.dart';
import 'treemap_density_resolver.dart';

final layoutConfigForSizeProvider =
    Provider.autoDispose.family<LayoutConfig, Size>((ref, size) {
  final resolved = ref.watch(treemapDensityForSizeProvider(size));
  return resolved.layoutConfig;
});
