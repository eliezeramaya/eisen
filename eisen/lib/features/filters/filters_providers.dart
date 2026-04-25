import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active category filters selected by the user in the UI.
/// Defaults to empty (no filtering applied).
final activeCategoryFiltersProvider =
    NotifierProvider<ActiveCategoryFilters, List<String>>(
        ActiveCategoryFilters.new);

class ActiveCategoryFilters extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  /// Update the list of active filters
  void update(List<String> newFilters) {
    state = newFilters;
  }
}

final activeKindFiltersProvider =
    NotifierProvider<ActiveKindFilters, List<EntryKind>>(
  ActiveKindFilters.new,
);

class ActiveKindFilters extends Notifier<List<EntryKind>> {
  @override
  List<EntryKind> build() => const <EntryKind>[];

  void update(List<EntryKind> newFilters) {
    state = newFilters;
  }
}

final activeHorizonFiltersProvider =
    NotifierProvider<ActiveHorizonFilters, List<TimeHorizon>>(
  ActiveHorizonFilters.new,
);

class ActiveHorizonFilters extends Notifier<List<TimeHorizon>> {
  @override
  List<TimeHorizon> build() => const <TimeHorizon>[];

  void update(List<TimeHorizon> newFilters) {
    state = newFilters;
  }
}

final activeEnergyFiltersProvider =
    NotifierProvider<ActiveEnergyFilters, List<EnergyLevel>>(
  ActiveEnergyFilters.new,
);

class ActiveEnergyFilters extends Notifier<List<EnergyLevel>> {
  @override
  List<EnergyLevel> build() => const <EnergyLevel>[];

  void update(List<EnergyLevel> newFilters) {
    state = newFilters;
  }
}

final activeConfidenceFiltersProvider =
    NotifierProvider<ActiveConfidenceFilters, List<ConfidenceLevel>>(
  ActiveConfidenceFilters.new,
);

class ActiveConfidenceFilters extends Notifier<List<ConfidenceLevel>> {
  @override
  List<ConfidenceLevel> build() => const <ConfidenceLevel>[];

  void update(List<ConfidenceLevel> newFilters) {
    state = newFilters;
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

String? _normalizedCategory(Task task) {
  final categoryId = task.categoryId?.trim().toLowerCase();
  if (categoryId != null && categoryId.isNotEmpty) return categoryId;
  final category = task.category?.trim().toLowerCase();
  if (category != null && category.isNotEmpty) return category;
  return null;
}
