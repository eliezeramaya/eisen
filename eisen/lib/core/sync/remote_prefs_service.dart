import 'package:eisen/core/services/ui_prefs.dart';

/// Remote preferences sync contract (no backend yet).
///
/// Implementations should be resilient: failures must bubble silently
/// to the caller so the local UX remains unaffected.
abstract interface class RemotePrefsService {
  Future<UiPrefsData?> fetchRemotePrefs();
  Future<void> pushRemotePrefs(UiPrefsData prefs);
  Future<UiPrefsData> resolveConflict({
    required UiPrefsData local,
    required UiPrefsData remote,
  });
}
