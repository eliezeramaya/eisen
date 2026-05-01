import 'dart:async';

import 'package:eisen/features/atlas/application/atlas_node_builder.dart';
import 'package:eisen/features/atlas/application/task_view_mode_prefs.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
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

class AtlasGroupingController extends Notifier<AtlasGrouping> {
  @override
  AtlasGrouping build() => AtlasGrouping.category;

  void update(AtlasGrouping grouping) {
    state = grouping;
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
  return buildAtlasNodes(tasks: tasks, grouping: grouping);
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

final atlasSelectedTaskProvider =
    NotifierProvider<AtlasSelectedTaskController, Task?>(
  AtlasSelectedTaskController.new,
);

class AtlasSelectedTaskController extends Notifier<Task?> {
  @override
  Task? build() => null;

  void select(Task? task) {
    state = task;
  }
}

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
