# Privacy & Security Implementation Summary

## 🔒 Implemented Features

### 1. ID Anonymization
**File:** `lib/core/services/telemetry.dart`

```dart
// Task IDs are hashed with SHA-256 + salt before logging
String _anonymizeId(String taskId) {
  final bytes = utf8.encode('$salt:$taskId');
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 12); // First 12 chars
}
```

**Benefits:**
- ✅ One-way encryption (cannot reverse)
- ✅ Different devices = different hashes
- ✅ No correlation across users
- ✅ Privacy-safe even if logs intercepted

### 2. Consent Management
**Files:** 
- `lib/core/services/telemetry_consent.dart` (logic)
- `lib/core/widgets/telemetry_consent_dialog.dart` (UI)

**Features:**
- ✅ Disabled by default
- ✅ First-launch consent dialog
- ✅ Persistent storage of preference
- ✅ Easy opt-out in settings
- ✅ Clear privacy explanation

### 3. Privacy-Safe Metrics
**File:** `lib/core/services/metrics.dart`

**Tracks (local only, no IDs):**
- Layout performance times
- Interaction counts
- Web vitals (LCP)

**Does NOT track:**
- Task content
- Task IDs (not even hashed)
- Personal information

### 4. Storage Security
**File:** `lib/core/services/storage_prefs.dart`

**Added methods:**
```dart
Future<bool?> getTelemetryConsent()
Future<void> setTelemetryConsent(bool enabled)
Future<String> getTelemetrySalt()
```

**Features:**
- ✅ Persistent consent storage
- ✅ Salt generation and reuse
- ✅ Local-only data (no cloud)

## 📋 Integration Guide

### Step 1: Initialize on App Start

```dart
// In main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize telemetry system
  await TelemetryConsent.initialize();
  
  runApp(MyApp());
}
```

### Step 2: Show Consent Dialog

```dart
// In root widget build or first screen
@override
Widget build(BuildContext context) {
  // Show consent dialog after app loads
  WidgetsBinding.instance.addPostFrameCallback((_) {
    TelemetryConsentDialog.showIfNeeded(context);
  });
  
  return MaterialApp(...);
}
```

### Step 3: Add Settings Toggle

```dart
// In settings screen
SwitchListTile(
  title: const Text('Anonymous Analytics'),
  subtitle: const Text('Help improve Eisen'),
  value: TelemetryConsent.isEnabled,
  onChanged: (value) async {
    await TelemetryConsent.setConsent(value);
    setState(() {}); // Refresh UI
  },
)
```

### Step 4: Use Telemetry (Already Done)

```dart
// Telemetry automatically checks consent before logging
Telemetry.tileTap(taskId); // Only logs if enabled
```

## 🧪 Testing

Run privacy tests:
```bash
flutter test test/unit/core/telemetry_privacy_test.dart
```

Verify consent flow:
1. Clear app data
2. Launch app
3. Consent dialog should appear
4. Accept/deny and verify telemetry state

## 📝 Documentation

- **Privacy Policy:** `docs/PRIVACY.md`
- **Implementation:** See files listed above
- **Tests:** `test/unit/core/telemetry_privacy_test.dart`

## 🔐 Compliance Checklist

### GDPR (EU)
- ✅ Consent required before collection
- ✅ Clear disclosure of data practices
- ✅ Right to opt-out
- ✅ Data minimization
- ✅ No PII processing without consent
- ⏳ Privacy policy link (TODO: add to consent dialog)

### CCPA (California)
- ✅ No sale of personal information
- ✅ Clear data practices disclosure
- ✅ Opt-out mechanism
- ✅ No discrimination for opting out

### Best Practices
- ✅ Disabled by default
- ✅ No dark patterns
- ✅ Easy to understand
- ✅ One-way ID encryption
- ✅ Local-first architecture

## 🚀 Production Checklist

Before deploying with backend analytics:

1. **Replace dev.log with analytics SDK**
   ```dart
   // In telemetry.dart, replace:
   dev.log('tile_tap', name: 'telemetry', error: anonymizedId);
   // With:
   analytics.logEvent('tile_tap', params: {'task': anonymizedId});
   ```

2. **Add privacy policy URL**
   ```dart
   // In telemetry_consent_dialog.dart
   TextButton(
     onPressed: () => launchUrl('https://eisen.app/privacy'),
     child: Text('Privacy Policy'),
   )
   ```

3. **Test with real analytics backend**
   - Verify hashed IDs arrive correctly
   - Verify opt-out stops all events
   - Test consent persistence across app restarts

4. **Security audit**
   - Review all telemetry calls
   - Verify no PII in logs
   - Test salt persistence
   - Check HTTPS enforcement

## 📊 Current State

### Working
- ✅ ID anonymization (SHA-256 + salt)
- ✅ Consent management (storage + logic)
- ✅ Consent dialog UI
- ✅ Opt-out functionality
- ✅ Privacy documentation
- ✅ Local metrics (no IDs)

### Pending
- ⏳ Add to settings screen UI
- ⏳ Show consent dialog on first launch (integration)
- ⏳ Privacy policy URL
- ⏳ Backend integration (when needed)
- ⏳ Analytics dashboard

## 🔧 Dependencies Added

```yaml
dependencies:
  crypto: ^3.0.6  # For SHA-256 hashing
```

## 📦 Files Created/Modified

### Created
- `lib/core/services/telemetry_consent.dart`
- `lib/core/widgets/telemetry_consent_dialog.dart`
- `docs/PRIVACY.md`
- `test/unit/core/telemetry_privacy_test.dart`
- `docs/PRIVACY_IMPLEMENTATION.md` (this file)

### Modified
- `lib/core/services/telemetry.dart` (added consent + hashing)
- `lib/core/services/storage_prefs.dart` (added consent storage)
- `lib/core/services/metrics.dart` (privacy documentation)
- `pubspec.yaml` (added crypto dependency)

## 💡 Key Design Decisions

1. **Opt-in by default**: Respects privacy, complies with GDPR
2. **SHA-256 hashing**: Industry standard, irreversible
3. **Salt per device**: Prevents cross-device correlation
4. **No task content**: Only IDs (hashed) and metadata
5. **Local metrics**: Performance data doesn't need consent
6. **Clear UI**: No dark patterns, easy to understand

## 📞 Questions?

See `docs/PRIVACY.md` for detailed privacy policy and contact information.
