import 'package:eisen/core/config/app_config.dart';
import 'package:eisen/core/feature_flags/feature_flags.dart';
import 'package:eisen/core/feature_flags/feature_flags_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/provider_container_factory.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('default flags are local-first', () {
    final flags = FeatureFlags.defaults(AppConfig.fromEnvironment());

    expect(flags.isEnabled(FeatureFlag.smartClassification), isTrue);
    expect(flags.isEnabled(FeatureFlag.archive), isTrue);
    expect(flags.isEnabled(FeatureFlag.cloudSync), isFalse);
    expect(flags.isEnabled(FeatureFlag.analytics), isFalse);
  });

  test('local override updates provider state', () async {
    final container = createTestProviderContainer();
    final controller = container.read(featureFlagsProvider.notifier);

    await controller.setLocalOverride(FeatureFlag.archive, false);

    expect(
      container.read(featureFlagsProvider).isEnabled(FeatureFlag.archive),
      isFalse,
    );
  });
}
