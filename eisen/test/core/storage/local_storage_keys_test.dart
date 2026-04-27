import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storage keys are non-empty and grouped', () {
    final keys = <String>[
      LocalStorageKeys.tasksPayload,
      LocalStorageKeys.telemetryConsent,
      LocalStorageKeys.filtersCategories,
      LocalStorageKeys.localSchemaVersion,
      LocalStorageKeys.featureFlagOverride('archive'),
    ];

    expect(keys.every((key) => key.isNotEmpty), isTrue);
    expect(LocalStorageKeys.filtersCategories.startsWith('filters.'), isTrue);
    expect(
      LocalStorageKeys.featureFlagOverride('archive')
          .startsWith('feature_flags.'),
      isTrue,
    );
  });
}
