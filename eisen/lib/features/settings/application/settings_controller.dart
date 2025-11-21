import 'dart:async';

import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/sync/remote_prefs_service.dart';
import 'package:eisen/core/sync/remote_prefs_service_noop.dart';
import 'package:eisen/features/settings/data/local/local_prefs_service.dart';
import 'package:eisen/features/settings/domain/models/user_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central controller for Settings-level preferences.
///
/// Today it wraps [UiPrefsData] and keeps a small amount of metadata
/// (like [CategoryUsage]) in [UserPrefs]. As the Settings feature grows
/// (remote sync, per-device overrides), this controller becomes the
/// single point of coordination.
class SettingsController extends Notifier<UserPrefs> {
  late final LocalPrefsService _local;
  late final RemotePrefsService _remote;

  @override
  UserPrefs build() {
    _local = LocalPrefsService(UiPrefs());
    _remote = ref.read(remotePrefsServiceProvider);
    _init();
    return UserPrefsDefaults.value;
  }

  Future<void> _init() async {
    try {
      final prefs = await _local.load();
      state = prefs;
    } catch (_) {
      // On any error, keep defaults; UiPrefs is resilient on its own.
    }
  }

  /// Applies the currently active [UiPrefsData] from [uiPrefsProvider].
  ///
  /// This is typically invoked after the user presses "Apply" on the
  /// Settings screen, once the underlying controllers have updated
  /// their persisted values.
  Future<void> applyChanges() async {
    final ui = ref.read(uiPrefsProvider);
    final next = UserPrefs(ui: ui, categoryUsage: state.categoryUsage);
    state = next;
    await _local.save(next);
    // Fire-and-forget remote sync; errors are silenced.
    unawaited(
      _remote
          .pushRemotePrefs(ui)
          .catchError((_) => null),
    );
  }

  /// Reloads preferences from local storage and updates the controller state.
  ///
  /// Useful after canceling an edit session or when external code mutates
  /// preferences outside of the Settings feature.
  Future<UserPrefs> reload() async {
    try {
      final prefs = await _local.load();
      state = prefs;
      return prefs;
    } catch (_) {
      return state;
    }
  }

  /// Returns domain-level defaults without persisting them.
  ///
  /// The caller (typically the Settings UI) can use this as the source
  /// of truth for "Reset to defaults" drafts, and only persist on Apply.
  UiPrefsData resetToDefaultsDraft() {
    final defaults = UserPrefsDefaults.value;
    state = defaults.copyWith(categoryUsage: state.categoryUsage);
    return defaults.ui;
  }

  /// Bumps usage counter for the given Settings category id.
  ///
  /// This can later be used to order categories by frequency of use on
  /// mobile layouts.
  void bumpCategoryUsage(String id) {
    final usage = [...state.categoryUsage];
    final idx = usage.indexWhere((u) => u.id == id);
    if (idx == -1) {
      usage.add(CategoryUsage(id: id, openCount: 1));
    } else {
      final current = usage[idx];
      usage[idx] = current.copyWith(openCount: current.openCount + 1);
    }
    state = state.copyWith(categoryUsage: usage);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, UserPrefs>(SettingsController.new);
