# Privacy & Security

## Overview

Eisen is designed with privacy-first principles. Your tasks and personal data never leave your device unless you explicitly enable telemetry.

## Data Storage

### Local Storage Only
- **Tasks**: Stored locally using `shared_preferences` (device-only)
- **Settings**: Stored locally (theme, UI preferences)
- **No cloud sync**: Your data stays on your device

### What We Store
- Task titles, descriptions, dates, priorities
- UI preferences (theme, compact mode, etc.)
- Local performance metrics (session-only)

### What We DON'T Store Remotely
- ❌ Task content
- ❌ Personal information
- ❌ Location data
- ❌ Device identifiers

## Telemetry & Analytics

### Opt-In Only
- Telemetry is **disabled by default**
- Consent dialog appears on first launch
- You can opt-out anytime in Settings

### What Telemetry Collects (if enabled)
- ✅ Performance metrics (layout render times, LCP)
- ✅ Feature usage (quadrant interactions, zoom events)
- ✅ Anonymous interaction counts
- ✅ Aggregated statistics

### ID Anonymization
When telemetry is enabled, task IDs are **hashed with a salt** before logging:

```dart
// Original ID (never sent)
String taskId = "t1";

// Hashed ID (sent to analytics)
String hashedId = sha256("salt:t1"); // e.g., "a3f8b9c2e1d4"
```

**Why this matters:**
- One-way encryption: Cannot reverse hash to get original ID
- No correlation: Different devices = different salts = different hashes
- Privacy-safe: Even if logs are intercepted, tasks cannot be identified

### Current Implementation
Telemetry currently uses `dart:developer.log()` for local debugging. 

**Before production backend:**
1. Implement consent UI in settings
2. Replace `dev.log()` with actual analytics SDK
3. Add privacy policy link
4. Test GDPR/CCPA compliance

## Compliance

### GDPR (EU)
- ✅ Consent required before collection
- ✅ Right to opt-out
- ✅ Data minimization (only collect what's needed)
- ✅ No personal data processing without consent

### CCPA (California)
- ✅ No sale of personal information
- ✅ Clear disclosure of data practices
- ✅ Opt-out mechanism available

## Security Best Practices

### Current
- ✅ Local-only data storage
- ✅ No authentication (no accounts = no passwords to leak)
- ✅ ID anonymization with SHA-256
- ✅ Salt persistence for consistency

### Future (if adding backend)
- [ ] HTTPS-only API calls
- [ ] End-to-end encryption for sync
- [ ] Secure token storage
- [ ] Rate limiting to prevent abuse
- [ ] Audit logging for security events

## User Controls

### Settings Screen
Add telemetry toggle to settings:

```dart
SwitchListTile(
  title: const Text('Anonymous Analytics'),
  subtitle: const Text('Help improve Eisen by sharing usage data'),
  value: TelemetryConsent.isEnabled,
  onChanged: (value) async {
    await TelemetryConsent.setConsent(value);
  },
);
```

### Data Export
Future feature: Allow users to export their data in JSON format for portability.

### Data Deletion
Users can clear all data:
1. Uninstall app → All local data removed
2. Reset to demo (in-app) → Clears tasks, keeps settings

## Development

### Testing Telemetry
```bash
# Disable telemetry in tests
Telemetry.setEnabled(false);

# Test consent flow
await TelemetryConsent.initialize();
expect(TelemetryConsent.shouldShowConsentDialog, true);
```

### Debugging
```bash
# View telemetry logs
flutter logs | grep telemetry

# Check consent status
await StoragePrefs().getTelemetryConsent();
```

## Contact

For privacy concerns or questions:
- GitHub Issues: [eliezeramaya/eisen](https://github.com/eliezeramaya/eisen/issues)
- Email: [Contact form on GitHub profile]

---

**Last Updated:** October 23, 2025  
**Version:** 1.0.0
