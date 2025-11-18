import 'package:eisen/features/settings/domain/models/user_prefs.dart';

/// Placeholder remote preferences service.
///
/// This interface is intentionally minimal; it allows the Settings feature
/// to be wired for remote sync later without changing the UI or domain.
abstract class RemotePrefsService {
  Future<UserPrefs> fetchRemotePrefs();
  Future<void> pushRemotePrefs(UserPrefs prefs);

  /// Simple conflict resolution strategy. For now, a last-write-wins policy
  /// can be implemented by the caller using timestamps; this method exists
  /// so the wiring is ready when remote sync is added.
  UserPrefs resolveConflict(UserPrefs local, UserPrefs remote);
}

