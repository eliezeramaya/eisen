import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/core/services/telemetry.dart';

/// Manages telemetry consent lifecycle.
///
/// Call [initialize] on app start to:
/// 1. Load consent status from storage
/// 2. Initialize telemetry salt for ID anonymization
/// 3. Configure telemetry based on user preference
///
/// Use [shouldShowConsentDialog] to check if consent banner is needed.
class TelemetryConsent {
  static final StoragePrefs _storage = StoragePrefs();
  static bool? _consentGiven;

  /// Initialize telemetry system on app start.
  /// 
  /// Returns true if this is first launch (consent not set).
  static Future<bool> initialize() async {
    // Load or generate salt for ID hashing
    final salt = await _storage.getTelemetrySalt();
    Telemetry.initSalt(salt);

    // Load consent status
    _consentGiven = await _storage.getTelemetryConsent();

    // Configure telemetry based on consent
    if (_consentGiven == true) {
      Telemetry.setEnabled(true);
    }

    // Return true if first launch (no consent recorded)
    return _consentGiven == null;
  }

  /// Check if consent dialog should be shown.
  /// Returns true on first launch when consent has never been set.
  static bool get shouldShowConsentDialog => _consentGiven == null;

  /// User grants consent for telemetry.
  static Future<void> grantConsent() async {
    _consentGiven = true;
    await _storage.setTelemetryConsent(true);
    Telemetry.setEnabled(true);
  }

  /// User denies consent for telemetry.
  static Future<void> denyConsent() async {
    _consentGiven = false;
    await _storage.setTelemetryConsent(false);
    Telemetry.setEnabled(false);
  }

  /// Toggle telemetry on/off (for settings screen).
  static Future<void> setConsent(bool enabled) async {
    if (enabled) {
      await grantConsent();
    } else {
      await denyConsent();
    }
  }

  /// Get current consent status.
  /// Returns null if never set, true if granted, false if denied.
  static bool? get consentGiven => _consentGiven;

  /// Check if telemetry is currently enabled.
  static bool get isEnabled => Telemetry.enabled;
}
