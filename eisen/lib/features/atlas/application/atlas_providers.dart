import 'dart:async';

import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/atlas/application/atlas_insights_engine.dart';
import 'package:eisen/features/atlas/application/atlas_node_builder.dart';
import 'package:eisen/features/atlas/application/atlas_zoom_controller.dart';
import 'package:eisen/features/atlas/application/task_view_mode_prefs.dart';
import 'package:eisen/features/atlas/data/atlas_grouping_prefs.dart';
import 'package:eisen/features/atlas/data/atlas_saved_views_repository.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/saved_atlas_view.dart';
import 'package:eisen/features/atlas/domain/task_view_mode.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:eisen/features/focus/domain/focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskViewModePrefsProvider = Provider<TaskViewModePrefs>(
  (ref) => const TaskViewModePrefs(),
);

final taskViewModeProvider =
    NotifierProvider<TaskViewModeController, TaskViewMode>(
  TaskViewModeController.new,
);

class TaskViewModeController extends Notifier<TaskViewMode> {
  late final TaskViewModePrefs _prefs;
  bool _hasLocalUpdate = false;

  @override
  TaskViewMode build() {
    _prefs = ref.read(taskViewModePrefsProvider);
    unawaited(_loadPersistedMode());
    return TaskViewMode.matrix;
  }

  Future<void> _loadPersistedMode() async {
    final persisted = await _prefs.load();
    if (!ref.mounted || _hasLocalUpdate) return;
    state = persisted;
  }

  void update(TaskViewMode mode) {
    _hasLocalUpdate = true;
    state = mode;
    unawaited(_prefs.save(mode));
  }
}

final atlasGroupingProvider =
    NotifierProvider<AtlasGroupingController, AtlasGrouping>(
  AtlasGroupingController.new,
);

final atlasGroupingPrefsProvider = Provider<AtlasGroupingPrefs>(
  (ref) => const AtlasGroupingPrefs(),
);

final atlasSavedViewsRepositoryProvider = Provider<AtlasSavedViewsRepository>(
  (ref) => const AtlasSavedViewsRepository(),
);

final savedAtlasViewsProvider =
    NotifierProvider<SavedAtlasViewsController, List<SavedAtlasView>>(
  SavedAtlasViewsController.new,
);

final activeSavedAtlasViewProvider =
    NotifierProvider<ActiveSavedAtlasViewController, String?>(
  ActiveSavedAtlasViewController.new,
);

class AtlasGroupingController extends Notifier<AtlasGrouping> {
  late final AtlasGroupingPrefs _prefs;
  bool _hasLocalUpdate = false;

  @override
  AtlasGrouping build() {
    _prefs = ref.read(atlasGroupingPrefsProvider);
    unawaited(_loadPersistedGrouping());
    return AtlasGrouping.category;
  }

  Future<void> _loadPersistedGrouping() async {
    final persisted = await _prefs.load();
    if (!ref.mounted || _hasLocalUpdate) return;
    state = persisted;
  }

  void update(AtlasGrouping grouping) {
    _hasLocalUpdate = true;
    state = grouping;
    unawaited(_prefs.save(grouping));
  }
}

class ActiveSavedAtlasViewController extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? viewId) {
    state = viewId;
  }
}

class SavedAtlasViewsController extends Notifier<List<SavedAtlasView>> {
  late final AtlasSavedViewsRepository _repository;
  bool _hasLocalUpdate = false;

  @override
  List<SavedAtlasView> build() {
    _repository = ref.read(atlasSavedViewsRepositoryProvider);
    unawaited(_loadPersistedViews());
    return const <SavedAtlasView>[];
  }

  Future<void> _loadPersistedViews() async {
    final loaded = await _repository.load();
    if (!ref.mounted || _hasLocalUpdate) return;
    state = loaded;
  }

  Future<SavedAtlasView> saveCurrentView(String name) async {
    final now = DateTime.now();
    final trimmedName = name.trim().isEmpty ? 'Vista Atlas' : name.trim();
    final view = SavedAtlasView(
      id: 'atlas-view-${now.microsecondsSinceEpoch}',
      name: trimmedName,
      grouping: ref.read(atlasGroupingProvider),
      filters: SavedAtlasFilters(
        categoryIds: ref.read(activeCategoryFiltersProvider),
        kinds: ref.read(activeKindFiltersProvider),
        horizons: ref.read(activeHorizonFiltersProvider),
        energies: ref.read(activeEnergyFiltersProvider),
        confidences: ref.read(activeConfidenceFiltersProvider),
      ),
      showArchived: ref.read(showArchivedProvider),
      semanticLevel: ref.read(atlasZoomProvider).semanticLevel,
      zoomScale: ref.read(atlasZoomProvider).scale,
      zoomOffset: ref.read(atlasZoomProvider).offset,
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, view];
    ref.read(activeSavedAtlasViewProvider.notifier).update(view.id);
    await _persist();
    return view;
  }

  Future<void> applyView(SavedAtlasView view) async {
    ref.read(atlasGroupingProvider.notifier).update(view.grouping);
    await ref
        .read(activeCategoryFiltersProvider.notifier)
        .update(view.filters.categoryIds);
    await ref
        .read(activeKindFiltersProvider.notifier)
        .update(view.filters.kinds);
    await ref
        .read(activeHorizonFiltersProvider.notifier)
        .update(view.filters.horizons);
    await ref
        .read(activeEnergyFiltersProvider.notifier)
        .update(view.filters.energies);
    await ref
        .read(activeConfidenceFiltersProvider.notifier)
        .update(view.filters.confidences);
    ref.read(showArchivedProvider.notifier).update(view.showArchived);
    ref.read(atlasZoomProvider.notifier).applySavedZoom(
          scale: view.zoomScale,
          offset: view.zoomOffset,
          semanticLevel: view.semanticLevel,
        );
    ref.read(atlasDrilldownPathProvider.notifier).clear();
    ref.read(activeSavedAtlasViewProvider.notifier).update(view.id);
  }

  Future<void> renameView(String viewId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    state = [
      for (final view in state)
        if (view.id == viewId)
          view.copyWith(name: trimmed, updatedAt: now)
        else
          view,
    ];
    await _persist();
  }

  Future<void> deleteView(String viewId) async {
    state = state.where((view) => view.id != viewId).toList(growable: false);
    if (ref.read(activeSavedAtlasViewProvider) == viewId) {
      ref.read(activeSavedAtlasViewProvider.notifier).update(null);
    }
    await _persist();
  }

  Future<void> _persist() async {
    _hasLocalUpdate = true;
    await _repository.save(state);
  }
}

final atlasTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(visibleMatrixTasksProvider);
  return tasks
      .where((task) => task.completedAt == null)
      .toList(growable: false);
});

final atlasNodesProvider = Provider<List<AtlasNode>>((ref) {
  final tasks = ref.watch(atlasTasksProvider);
  final grouping = ref.watch(atlasGroupingProvider);
  final labelStyle = ref.watch(
    uiPrefsProvider.select((prefs) => prefs.quadrantLabelStyle),
  );
  return buildAtlasNodes(
    tasks: tasks,
    grouping: grouping,
    quadrantLabelStyle: labelStyle,
  );
});

final atlasInsightsProvider = Provider<List<AtlasInsight>>((ref) {
  final tasks = ref.watch(atlasTasksProvider);
  return buildAtlasInsights(tasks: tasks, now: DateTime.now());
});

final atlasInsightTaskIdsProvider = Provider<Set<String>>((ref) {
  final insights = ref.watch(atlasInsightsProvider);
  return {
    for (final insight in insights) ...insight.taskIds,
  };
});

final atlasResolvedDrilldownPathProvider = Provider<List<AtlasNode>>((ref) {
  final roots = ref.watch(atlasNodesProvider);
  final requestedPath = ref.watch(atlasDrilldownPathProvider);
  return resolveAtlasDrilldownPath(
    roots: roots,
    requestedPath: requestedPath,
  );
});

final atlasVisibleNodesProvider = Provider<List<AtlasNode>>((ref) {
  final roots = ref.watch(atlasNodesProvider);
  final path = ref.watch(atlasResolvedDrilldownPathProvider);
  if (path.isEmpty) return roots;
  return path.last.children;
});

List<AtlasNode> resolveAtlasDrilldownPath({
  required List<AtlasNode> roots,
  required List<AtlasNode> requestedPath,
}) {
  var siblings = roots;
  final resolved = <AtlasNode>[];
  for (final requested in requestedPath) {
    AtlasNode? match;
    for (final node in siblings) {
      if (node.id == requested.id && node.children.isNotEmpty) {
        match = node;
        break;
      }
    }
    if (match == null) break;
    resolved.add(match);
    siblings = match.children;
  }
  return resolved;
}

final atlasFocusedTaskIdsProvider = Provider<Set<String>>((ref) {
  final focus = ref.watch(focusControllerProvider);
  final state = focus.asData?.value;
  if (state == null || !state.isRunning || state.linkedTask == null) {
    return const <String>{};
  }
  return {state.linkedTask!.id};
});

final atlasSelectedTaskIdProvider =
    NotifierProvider<AtlasSelectedTaskIdController, String?>(
  AtlasSelectedTaskIdController.new,
);

class AtlasSelectedTaskIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? taskId) {
    state = taskId;
  }
}

final atlasSelectedTaskProvider = Provider<Task?>((ref) {
  final selectedTaskId = ref.watch(atlasSelectedTaskIdProvider);
  if (selectedTaskId == null) return null;
  final tasks = ref.watch(atlasTasksProvider);
  for (final task in tasks) {
    if (task.id == selectedTaskId) return task;
  }
  return null;
});

final atlasDrilldownPathProvider =
    NotifierProvider<AtlasDrilldownPathController, List<AtlasNode>>(
  AtlasDrilldownPathController.new,
);

class AtlasDrilldownPathController extends Notifier<List<AtlasNode>> {
  @override
  List<AtlasNode> build() => const <AtlasNode>[];

  void update(List<AtlasNode> path) {
    state = path;
  }

  void enter(AtlasNode node) {
    if (node.children.isEmpty) return;
    state = [...state, node];
  }

  void jumpTo(int index) {
    if (index < 0) {
      clear();
      return;
    }
    state = state.take(index + 1).toList(growable: false);
  }

  void clear() {
    state = const <AtlasNode>[];
  }
}

final atlasHasActiveFiltersProvider = Provider<bool>((ref) {
  return ref.watch(activeCategoryFiltersProvider).isNotEmpty ||
      ref.watch(activeKindFiltersProvider).isNotEmpty ||
      ref.watch(activeHorizonFiltersProvider).isNotEmpty ||
      ref.watch(activeEnergyFiltersProvider).isNotEmpty ||
      ref.watch(activeConfidenceFiltersProvider).isNotEmpty;
});

void clearAtlasBackedFilters(WidgetRef ref) {
  ref.read(activeCategoryFiltersProvider.notifier).update(const <String>[]);
  ref.read(activeKindFiltersProvider.notifier).update(const <EntryKind>[]);
  ref.read(activeHorizonFiltersProvider.notifier).update(const <TimeHorizon>[]);
  ref.read(activeEnergyFiltersProvider.notifier).update(const <EnergyLevel>[]);
  ref
      .read(activeConfidenceFiltersProvider.notifier)
      .update(const <ConfidenceLevel>[]);
}
