import 'dart:async';

import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kCategoryFiltersKey = 'filters.categories';
const _kKindFiltersKey = 'filters.kinds';
const _kHorizonFiltersKey = 'filters.horizons';
const _kEnergyFiltersKey = 'filters.energies';
const _kConfidenceFiltersKey = 'filters.confidences';

final filtersStorageProvider = Provider<StoragePrefs>((ref) => StoragePrefs());

final activeCategoryFiltersProvider =
    NotifierProvider<ActiveCategoryFilters, List<String>>(
  ActiveCategoryFilters.new,
);

final showArchivedProvider = NotifierProvider<ShowArchived, bool>(
  ShowArchived.new,
);

class ShowArchived extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) {
    state = value;
  }
}

class ActiveCategoryFilters extends Notifier<List<String>> {
  late final StoragePrefs _storage = ref.read(filtersStorageProvider);

  @override
  List<String> build() {
    unawaited(_loadAsync());
    return const <String>[];
  }

  Future<void> _loadAsync() async {
    final loaded = await _storage.loadStringListField(_kCategoryFiltersKey);
    if (ref.mounted) {
      state = loaded;
    }
  }

  Future<void> update(List<String> newFilters) async {
    state = newFilters;
    await _storage.saveStringListField(_kCategoryFiltersKey, newFilters);
  }
}

final activeKindFiltersProvider =
    NotifierProvider<ActiveKindFilters, List<EntryKind>>(
  ActiveKindFilters.new,
);

class ActiveKindFilters extends Notifier<List<EntryKind>> {
  late final StoragePrefs _storage = ref.read(filtersStorageProvider);

  @override
  List<EntryKind> build() {
    unawaited(_loadAsync());
    return const <EntryKind>[];
  }

  Future<void> _loadAsync() async {
    final names = await _storage.loadStringListField(_kKindFiltersKey);
    if (!ref.mounted) {
      return;
    }
    state = _parseEnumList(names, EntryKind.values);
  }

  Future<void> update(List<EntryKind> newFilters) async {
    state = newFilters;
    await _storage.saveStringListField(
      _kKindFiltersKey,
      newFilters.map((item) => item.name).toList(growable: false),
    );
  }
}

final activeHorizonFiltersProvider =
    NotifierProvider<ActiveHorizonFilters, List<TimeHorizon>>(
  ActiveHorizonFilters.new,
);

class ActiveHorizonFilters extends Notifier<List<TimeHorizon>> {
  late final StoragePrefs _storage = ref.read(filtersStorageProvider);

  @override
  List<TimeHorizon> build() {
    unawaited(_loadAsync());
    return const <TimeHorizon>[];
  }

  Future<void> _loadAsync() async {
    final names = await _storage.loadStringListField(_kHorizonFiltersKey);
    if (!ref.mounted) {
      return;
    }
    state = _parseEnumList(names, TimeHorizon.values);
  }

  Future<void> update(List<TimeHorizon> newFilters) async {
    state = newFilters;
    await _storage.saveStringListField(
      _kHorizonFiltersKey,
      newFilters.map((item) => item.name).toList(growable: false),
    );
  }
}

final activeEnergyFiltersProvider =
    NotifierProvider<ActiveEnergyFilters, List<EnergyLevel>>(
  ActiveEnergyFilters.new,
);

class ActiveEnergyFilters extends Notifier<List<EnergyLevel>> {
  late final StoragePrefs _storage = ref.read(filtersStorageProvider);

  @override
  List<EnergyLevel> build() {
    unawaited(_loadAsync());
    return const <EnergyLevel>[];
  }

  Future<void> _loadAsync() async {
    final names = await _storage.loadStringListField(_kEnergyFiltersKey);
    if (!ref.mounted) {
      return;
    }
    state = _parseEnumList(names, EnergyLevel.values);
  }

  Future<void> update(List<EnergyLevel> newFilters) async {
    state = newFilters;
    await _storage.saveStringListField(
      _kEnergyFiltersKey,
      newFilters.map((item) => item.name).toList(growable: false),
    );
  }
}

final activeConfidenceFiltersProvider =
    NotifierProvider<ActiveConfidenceFilters, List<ConfidenceLevel>>(
  ActiveConfidenceFilters.new,
);

class ActiveConfidenceFilters extends Notifier<List<ConfidenceLevel>> {
  late final StoragePrefs _storage = ref.read(filtersStorageProvider);

  @override
  List<ConfidenceLevel> build() {
    unawaited(_loadAsync());
    return const <ConfidenceLevel>[];
  }

  Future<void> _loadAsync() async {
    final names = await _storage.loadStringListField(_kConfidenceFiltersKey);
    if (!ref.mounted) {
      return;
    }
    state = _parseEnumList(names, ConfidenceLevel.values);
  }

  Future<void> update(List<ConfidenceLevel> newFilters) async {
    state = newFilters;
    await _storage.saveStringListField(
      _kConfidenceFiltersKey,
      newFilters.map((item) => item.name).toList(growable: false),
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
    final selected =
        categoryIds.map((item) => item.trim().toLowerCase()).toSet();
    if (taskCategory == null || !selected.contains(taskCategory)) {
      return false;
    }
  }

  if (kinds.isNotEmpty && !kinds.contains(task.kind)) {
    return false;
  }
  if (horizons.isNotEmpty &&
      (task.horizon == null || !horizons.contains(task.horizon))) {
    return false;
  }
  if (energies.isNotEmpty &&
      (task.energy == null || !energies.contains(task.energy))) {
    return false;
  }
  if (confidences.isNotEmpty &&
      (task.classificationConfidence == null ||
          !confidences.contains(task.classificationConfidence))) {
    return false;
  }

  return true;
}

List<T> _parseEnumList<T extends Enum>(
  List<String> names,
  List<T> values,
) {
  final parsed = <T>[];
  for (final name in names) {
    for (final value in values) {
      if (value.name == name) {
        parsed.add(value);
        break;
      }
    }
  }
  return parsed;
}

String? _normalizedCategory(Task task) {
  final categoryId = task.categoryId?.trim().toLowerCase();
  if (categoryId != null && categoryId.isNotEmpty) {
    return categoryId;
  }
  final category = task.category?.trim().toLowerCase();
  if (category != null && category.isNotEmpty) {
    return category;
  }
  return null;
}
