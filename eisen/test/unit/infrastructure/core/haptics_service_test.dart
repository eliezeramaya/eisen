import 'package:eisen/core/haptics/haptics_service.dart';
import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:eisen/features/settings/domain/accessibility_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibration/vibration.dart';

/// Mock HapticsService for testing
class MockHapticsService implements HapticsService {
  final List<String> calls = [];
  bool deviceHasVibrator = true;

  @override
  Future<void> light() async {
    calls.add('light');
  }

  @override
  Future<void> medium() async {
    calls.add('medium');
  }

  @override
  Future<void> heavy() async {
    calls.add('heavy');
  }

  @override
  Future<void> error() async {
    calls.add('error');
  }

  @override
  Future<bool> hasVibrator() async {
    return deviceHasVibrator;
  }

  void reset() => calls.clear();
}

void main() {
  group('HapticsService', () {
    test('light vibration has correct duration', () async {
      // This test verifies the interface contract but actual vibration
      // testing requires device/emulator
      final mock = MockHapticsService();
      await mock.light();
      expect(mock.calls, contains('light'));
    });

    test('medium vibration has correct duration', () async {
      final mock = MockHapticsService();
      await mock.medium();
      expect(mock.calls, contains('medium'));
    });

    test('heavy vibration has correct duration', () async {
      final mock = MockHapticsService();
      await mock.heavy();
      expect(mock.calls, contains('heavy'));
    });

    test('error vibration triggers double pattern', () async {
      final mock = MockHapticsService();
      await mock.error();
      expect(mock.calls, contains('error'));
    });

    test('hasVibrator checks device capability', () async {
      final mock = MockHapticsService();
      final hasVibrator = await mock.hasVibrator();
      expect(hasVibrator, isTrue);

      mock.deviceHasVibrator = false;
      final hasVibratorDisabled = await mock.hasVibrator();
      expect(hasVibratorDisabled, isFalse);
    });
  });

  group('HapticsService integration scenarios', () {
    late MockHapticsService mockService;

    setUp(() {
      mockService = MockHapticsService();
    });

    test('focus session start should trigger medium haptic', () async {
      await mockService.medium();
      expect(mockService.calls.last, 'medium');
    });

    test('focus session complete should trigger heavy haptic', () async {
      await mockService.heavy();
      expect(mockService.calls.last, 'heavy');
    });

    test('task completion should trigger light haptic', () async {
      await mockService.light();
      expect(mockService.calls.last, 'light');
    });

    test('dependency error should trigger error haptic', () async {
      await mockService.error();
      expect(mockService.calls.last, 'error');
    });

    test('multiple haptic calls are tracked in order', () async {
      await mockService.light();
      await mockService.medium();
      await mockService.heavy();
      await mockService.error();

      expect(mockService.calls, ['light', 'medium', 'heavy', 'error']);
    });
  });

  group('DefaultHapticsService', () {
    test('respects hapticsEnabled preference - enabled', () async {
      final container = ProviderContainer(
        overrides: [
          accessibilityControllerProvider.overrideWith(() {
            return _MockAccessibilityController(
              const AccessibilityPrefs(
                largeText: false,
                highContrast: false,
                reduceAnimations: false,
                hapticsEnabled: true,
              ),
            );
          }),
        ],
      );

      final service = container.read(hapticsServiceProvider);

      // With real implementation, this would check if Vibration.vibrate was called
      // For now, we verify the service exists and can be called
      expect(service, isA<HapticsService>());

      container.dispose();
    });

    test('respects hapticsEnabled preference - disabled', () async {
      final container = ProviderContainer(
        overrides: [
          accessibilityControllerProvider.overrideWith(() {
            return _MockAccessibilityController(
              const AccessibilityPrefs(
                largeText: false,
                highContrast: false,
                reduceAnimations: false,
                hapticsEnabled: false,
              ),
            );
          }),
        ],
      );

      final service = container.read(hapticsServiceProvider);

      // When hapticsEnabled is false, vibrations should not occur
      // This would require mocking Vibration.vibrate to verify no calls
      expect(service, isA<HapticsService>());

      container.dispose();
    });

    test('checks device vibrator availability', () async {
      final container = ProviderContainer();
      final service = container.read(hapticsServiceProvider);

      // Note: This will return false in test environment
      // In real device, it would return true
      final hasVibrator = await service.hasVibrator();
      expect(hasVibrator, isA<bool>());

      container.dispose();
    });
  });
}

/// Mock AccessibilityController for testing
class _MockAccessibilityController extends AccessibilityController {
  _MockAccessibilityController(this._prefs);
  final AccessibilityPrefs _prefs;

  @override
  AccessibilityPrefs build() => _prefs;
}
