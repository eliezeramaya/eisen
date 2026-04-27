import 'dart:async';
import 'dart:convert';

import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

const _kCategoryFiltersKey = 'eisen.filters.categories.v1';
const _kKindFiltersKey = 'eisen.filters.kinds.v1';
const _kHorizonFiltersKey = 'eisen.filters.horizons.v1';
const _kEnergyFiltersKey = 'eisen.filters.energies.v1';
const _kConfidenceFiltersKey = 'eisen.filters.confidences.v1';

Future<List<String>> _loadStringList(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(key);
  if (raw == null) return const <String>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return const <String>[];
}

Future<void> _saveStringList(String key, List<String> values) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, jsonEncode(values));
}

// ---------------------------------------------------------------------------
// Category filters
// ---------------------------------------------------------------------------

/// Active category filters selected by the user in the UI.
/// Persisted between sessions via SharedPreferences.
final activeCategoryFiltersProvider = NotifierProvider<ActiveCategoryFilters, List<String>>(ActiveCategoryFilters.new);

class ActiveCategoryFilters extends Notifier<List<String>> {
  @override
  List<String> build() {
    unawaited(_loadAsync());
    return const <String>[];
  }

  Future<void> _loadAsync() async {
    final loaded = await _loadStringList(_kCategoryFiltersKey);
    if (loaded.isNotEmpty) state = loaded;
  }

  void update(List<String> newFilters) {
    state = newFilters;
    unawaited(_saveStringList(_kCategoryFiltersKey, newFilters));
  }
}

// ---------------------------------------------------------------------------
// Kind filters
// ---------------------------------------------------------------------------

final activeKindFiltersProvider = NotifierProvider<ActiveKindFilters, List<EntryKind>>(
  ActiveKindFilters.new,
);

class ActiveKindFilters extends Notifier<List<EntryKind>> {
  @override
  List<EntryKind> build() {
    unawaited(_loadAsync());
    return const <EntryKind>[];
  }

  Future<void> _loadAsync() async {
    final names = await _loadStringList(_kKindFiltersKey);
    if (names.isEmpty) return;
    final parsed =
        names.map((n) => EntryKind.values.where((e) => e.name == n).firstOrNull).whereType<EntryKind>().toList();
    if (parsed.isNotEmpty) state = parsed;
  }

  void update(List<EntryKind> newFilters) {
    state = newFilters;
    unawaited(
      _saveStringList(_kKindFiltersKey, newFilters.map((e) => e.name).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizon filters
// ---------------------------------------------------------------------------

final activeHorizonFiltersProvider = NotifierProvider<ActiveHorizonFilters, List<TimeHorizon>>(
  ActiveHorizonFilters.new,
);

class ActiveHorizonFilters extends Notifier<List<TimeHorizon>> {
  @override
  List<TimeHorizon> build() {
    unawaited(_loadAsync());
    return const <TimeHorizon>[];
  }

  Future<void> _loadAsync() async {
    final names = await _loadStringList(_kHorizonFiltersKey);
    if (names.isEmpty) return;
    final parsed =
        names.map((n) => TimeHorizon.values.where((e) => e.name == n).firstOrNull).whereType<TimeHorizon>().toList();
    if (parsed.isNotEmpty) state = parsed;
  }

  void update(List<TimeHorizon> newFilters) {
    state = newFilters;
    unawaited(
      _saveStringList(_kHorizonFiltersKey, newFilters.map((e) => e.name).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Energy filters
// ---------------------------------------------------------------------------

final activeEnergyFiltersProvider = NotifierProvider<ActiveEnergyFilters, List<EnergyLevel>>(
  ActiveEnergyFilters.new,
);

class ActiveEnergyFilters extends Notifier<List<EnergyLevel>> {
  @override
  List<EnergyLevel> build() {
    unawaited(_loadAsync());
    return const <EnergyLevel>[];
  }

  Future<void> _loadAsync() async {
    final names = await _loadStringList(_kEnergyFiltersKey);
    if (names.isEmpty) return;
    final parsed =
        names.map((n) => EnergyLevel.values.where((e) => e.name == n).firstOrNull).whereType<EnergyLevel>().toList();
    if (parsed.isNotEmpty) state = parsed;
  }

  void update(List<EnergyLevel> newFilters) {
    state = newFilters;
    unawaited(
      _saveStringList(_kEnergyFiltersKey, newFilters.map((e) => e.name).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Confidence filters
// ---------------------------------------------------------------------------

final activeConfidenceFiltersProvider = NotifierProvider<ActiveConfidenceFilters, List<ConfidenceLevel>>(
  ActiveConfidenceFilters.new,
);

class ActiveConfidenceFilters extends Notifier<List<ConfidenceLevel>> {
  @override
  List<ConfidenceLevel> build() {
    unawaited(_loadAsync());
    return const <ConfidenceLevel>[];
  }

  Future<void> _loadAsync() async {
    final names = await _loadStringList(_kConfidenceFiltersKey);
    if (names.isEmpty) return;
    final parsed = names
        .map(
          (n) => ConfidenceLevel.values.where((e) => e.name == n).firstOrNull,
        )
        .whereType<ConfidenceLevel>()
        .toList();
    if (parsed.isNotEmpty) state = parsed;
  }

  void update(List<ConfidenceLevel> newFilters) {
    state = newFilters;
    unawaited(
      _saveStringList(_kConfidenceFiltersKey, newFilters.map((e) => e.name).toList()),
    );
  }
}

bool matchesTaskClassificationFilters({
  required Task task,
  List<String> categoryIds = const <String>[],
  List<EntryKind> kinds = const <EntryKind>[],
  List<TimeHorizon> horizons = const <TimeHorizon>[],
  List<EnergyLevel> energies = const <EnergyLevel>[],
  List<ConfidenceLevel> confidences = const <ConfidenceLevel>[],
}) {
  if (categoryIds.isNotEmpty) {
    final taskCategory = _normalizedCategory(task);
    final selected = categoryIds.map((item) => item.trim().toLowerCase()).toSet();
    if (taskCategory == null || !selected.contains(taskCategory)) {
      return false;
    }
  }

  if (kinds.isNotEmpty && !kinds.contains(task.kind)) {
    return false;
  }
  if (horizons.isNotEmpty && (task.horizon == null || !horizons.contains(task.horizon))) {
    return false;
  }
  if (energies.isNotEmpty && (task.energy == null || !energies.contains(task.energy))) {
    return false;
  }
  if (confidences.isNotEmpty &&
      (task.classificationConfidence == null || !confidences.contains(task.classificationConfidence))) {
    return false;
  }

  return true;
}

String? _normalizedCategory(Task task) {
  final categoryId = task.categoryId?.trim().toLowerCase();
  if (categoryId != null && categoryId.isNotEmpty) return categoryId;
  final category = task.category?.trim().toLowerCase();
  if (category != null && category.isNotEmpty) return category;
  return null;
}
