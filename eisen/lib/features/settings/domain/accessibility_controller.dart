import 'dart:async';

import 'package:eisen/features/settings/data/accessibility_prefs_repository.dart';
import 'package:eisen/features/settings/domain/accessibility_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccessibilityController extends AsyncNotifier<AccessibilityPrefs> {
  late final AccessibilityPrefsRepository _repo;

  @override
  FutureOr<AccessibilityPrefs> build() async {
    _repo = ref.read(accessibilityPrefsRepositoryProvider);
    final prefs = await _repo.load();
    return prefs;
  }

  Future<void> _save(AccessibilityPrefs prefs) async {
    state = AsyncData(prefs);
    await _repo.save(prefs);
  }

  Future<void> toggleLargeText(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(largeText: value));
  }

  Future<void> toggleHighContrast(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(highContrast: value));
  }

  Future<void> toggleReduceAnimations(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(reduceAnimations: value));
  }

  Future<void> toggleHaptics(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _save(current.copyWith(hapticsEnabled: value));
  }
}

final accessibilityControllerProvider =
    AsyncNotifierProvider<AccessibilityController, AccessibilityPrefs>(
        AccessibilityController.new);
