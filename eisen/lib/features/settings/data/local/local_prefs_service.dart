import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/settings/domain/models/user_prefs.dart';

/// Local preferences service for the Settings feature.
///
/// This is a thin wrapper over [UiPrefs] that exposes a domain-level
/// [UserPrefs] model. Today it only stores [UiPrefsData], but it can
/// evolve to persist additional Settings-related data (e.g. categoryUsage).
class LocalPrefsService {
  LocalPrefsService(this._uiPrefs);
  final UiPrefs _uiPrefs;

  Future<UserPrefs> load() async {
    final ui = await _uiPrefs.load();
    // Category usage is currently kept in memory only; defaults to empty.
    return UserPrefs(ui: ui, categoryUsage: const <CategoryUsage>[]);
  }

  Future<void> save(UserPrefs prefs) async {
    await _uiPrefs.save(prefs.ui);
    // categoryUsage persistence can be added here in the future.
  }
}

