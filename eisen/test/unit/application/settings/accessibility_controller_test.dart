import 'package:eisen/features/settings/data/accessibility_prefs_repository.dart';
import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AccessibilityController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults when empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs =
          await container.read(accessibilityControllerProvider.future);
      expect(prefs.largeText, isFalse);
      expect(prefs.highContrast, isFalse);
      expect(prefs.reduceAnimations, isFalse);
      expect(prefs.hapticsEnabled, isTrue);
    });

    test('toggles persist and reload', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Ensure initial load
      await container.read(accessibilityControllerProvider.future);
      final ctrl = container.read(accessibilityControllerProvider.notifier);
      await ctrl.toggleLargeText(true);
      await ctrl.toggleHighContrast(true);
      await ctrl.toggleReduceAnimations(true);
      await ctrl.toggleHaptics(false);

      final loadedState =
          container.read(accessibilityControllerProvider).asData?.value;
      expect(loadedState?.largeText, isTrue);
      expect(loadedState?.highContrast, isTrue);
      expect(loadedState?.reduceAnimations, isTrue);
      expect(loadedState?.hapticsEnabled, isFalse);
    });

    test('corrupt data falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'settings.accessibility.v1': '{bad json',
      });
      final repo = AccessibilityPrefsLocalRepository();
      final prefs = await repo.load();
      expect(prefs.largeText, isFalse);
      expect(prefs.hapticsEnabled, isTrue);
    });
  });
}
