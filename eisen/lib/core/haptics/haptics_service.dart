import 'package:eisen/features/settings/domain/accessibility_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

/// Abstract service for haptic feedback
abstract class HapticsService {
  /// Light vibration for subtle feedback (task completion, selection)
  Future<void> light();

  /// Medium vibration for standard feedback (focus start, notifications)
  Future<void> medium();

  /// Heavy vibration for important feedback (focus end, timer complete)
  Future<void> heavy();

  /// Error vibration for alerts (validation errors, dependency conflicts)
  Future<void> error();

  /// Check if haptic feedback is available on device
  Future<bool> hasVibrator();
}

/// Default implementation using the vibration package
class DefaultHapticsService implements HapticsService {
  DefaultHapticsService(this._ref);

  final Ref _ref;
  bool? _hasVibrator;

  /// Check if haptics are enabled in accessibility settings
  bool get _isEnabled {
    final asyncPrefs = _ref.read(accessibilityControllerProvider);
    final prefs = asyncPrefs.asData?.value;
    return prefs?.hapticsEnabled ?? true;
  }

  @override
  Future<bool> hasVibrator() async {
    if (_hasVibrator != null) return _hasVibrator!;
    final hasDevice = await Vibration.hasVibrator();
    _hasVibrator = hasDevice;
    return _hasVibrator ?? false;
  }

  /// Execute vibration if enabled and available
  Future<void> _vibrate(int duration) async {
    if (!_isEnabled) return;

    final hasDevice = await hasVibrator();
    if (!hasDevice) return;

    await Vibration.vibrate(duration: duration);
  }

  @override
  Future<void> light() async {
    await _vibrate(20); // 20ms - subtle, quick
  }

  @override
  Future<void> medium() async {
    await _vibrate(50); // 50ms - standard feedback
  }

  @override
  Future<void> heavy() async {
    await _vibrate(100); // 100ms - noticeable, important
  }

  @override
  Future<void> error() async {
    // Double vibration pattern for errors: 50ms, 50ms pause, 50ms
    if (!_isEnabled) return;

    final hasDevice = await hasVibrator();
    if (!hasDevice) return;

    await Vibration.vibrate(duration: 50);
    await Future.delayed(const Duration(milliseconds: 50));
    await Vibration.vibrate(duration: 50);
  }
}

/// Provider for haptics service
final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return DefaultHapticsService(ref);
});
