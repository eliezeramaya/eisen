import 'dart:async';

import 'package:eisen/core/feature_flags/feature_flags.dart';
import 'package:eisen/core/observability/observability_provider.dart';
import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final featureFlagsProvider =
    NotifierProvider<FeatureFlagsController, FeatureFlags>(
  FeatureFlagsController.new,
);

class FeatureFlagsController extends Notifier<FeatureFlags> {
  @override
  FeatureFlags build() {
    final defaults = FeatureFlags.defaults(ref.watch(appConfigProvider));
    unawaited(_loadOverrides(defaults));
    return defaults;
  }

  Future<void> setLocalOverride(FeatureFlag flag, bool? enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = LocalStorageKeys.featureFlagOverride(flag.storageName);
    if (enabled == null) {
      await prefs.remove(key);
      await _loadOverrides(FeatureFlags.defaults(ref.read(appConfigProvider)));
    } else {
      await prefs.setBool(key, enabled);
      state = state.copyWithOverride(flag, enabled);
    }
  }

  Future<void> _loadOverrides(FeatureFlags defaults) async {
    final prefs = await SharedPreferences.getInstance();
    var next = defaults;
    for (final flag in FeatureFlag.values) {
      final key = LocalStorageKeys.featureFlagOverride(flag.storageName);
      if (prefs.containsKey(key)) {
        next = next.copyWithOverride(flag, prefs.getBool(key));
      }
    }
    if (ref.mounted) {
      state = next;
    }
  }
}
