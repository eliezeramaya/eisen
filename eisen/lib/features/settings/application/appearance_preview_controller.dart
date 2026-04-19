import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight preview state for the Appearance section.
///
/// This mirrors the most relevant fields from [UiPrefsData] but lives in a
/// separate provider so changes only affect the preview card until the user
/// presses Apply.
@immutable
class AppearancePreviewState {
  const AppearancePreviewState({
    required this.themeMode,
    required this.densityPreset,
    required this.minimal,
    required this.compact,
    required this.textScaleLevel,
  }); // 1..5

  factory AppearancePreviewState.fromPrefs(UiPrefsData prefs) {
    return AppearancePreviewState(
      themeMode: prefs.themeMode,
      densityPreset: prefs.densityPreset,
      minimal: prefs.minimal,
      compact: prefs.compact,
      textScaleLevel: prefs.textScaleLevel,
    );
  }

  final ThemeMode themeMode;
  final String densityPreset; // 'auto' | 'comfy' | 'compact' | 'ultra'
  final bool minimal;
  final bool compact;
  final int textScaleLevel;

  AppearancePreviewState copyWith({
    ThemeMode? themeMode,
    String? densityPreset,
    bool? minimal,
    bool? compact,
    int? textScaleLevel,
  }) {
    return AppearancePreviewState(
      themeMode: themeMode ?? this.themeMode,
      densityPreset: densityPreset ?? this.densityPreset,
      minimal: minimal ?? this.minimal,
      compact: compact ?? this.compact,
      textScaleLevel: textScaleLevel ?? this.textScaleLevel,
    );
  }
}

class AppearancePreviewController extends Notifier<AppearancePreviewState> {
  @override
  AppearancePreviewState build() {
    final prefs = ref.read(uiPrefsProvider);
    return AppearancePreviewState.fromPrefs(prefs);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setDensityPreset(String preset) {
    state = state.copyWith(densityPreset: preset);
  }

  void setMinimal(bool value) {
    state = state.copyWith(minimal: value);
  }

  void setCompact(bool value) {
    state = state.copyWith(compact: value);
  }

  void setTextScaleLevel(int level) {
    final v = level.clamp(1, 5);
    state = state.copyWith(textScaleLevel: v);
  }

  /// Re-syncs preview from the globally persisted prefs (used on Cancel).
  void resetFromPrefs() {
    final prefs = ref.read(uiPrefsProvider);
    state = AppearancePreviewState.fromPrefs(prefs);
  }
}

final appearancePreviewProvider =
    NotifierProvider<AppearancePreviewController, AppearancePreviewState>(
        AppearancePreviewController.new);
