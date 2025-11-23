import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';

/// Provider for managing task dependencies and validation.
///
/// Provides methods to add, remove, and validate dependencies between tasks.
class DependenciesController extends Notifier<Map<String, TaskDependency>> {
  @override
  Map<String, TaskDependency> build() {
    // Build initial dependencies from tasks
    final tasks = ref.watch(matrixTasksProvider);
    final dependencies = <String, TaskDependency>{};

    for (final task in tasks) {
      if (task.dependencies.isEmpty) continue;

      // Create TaskDependency objects from task.dependencies list
      for (final prerequisiteId in task.dependencies) {
        final key = _makeKey(prerequisiteId, task.id);
        dependencies[key] = TaskDependency(
          prerequisiteId: prerequisiteId,
          dependentId: task.id,
          type: DependencyType.finishToStart, // Default type
        );
      }
    }

    return dependencies;
  }

  String _makeKey(String prerequisiteId, String dependentId) {
    return '$prerequisiteId->$dependentId';
  }

  /// Adds a new dependency between tasks.
  ///
  /// Returns a [CycleDetectionResult] indicating whether the dependency
  /// would create a cycle. If valid, the dependency is added.
  CycleDetectionResult addDependency({
    required String prerequisiteId,
    required String dependentId,
    DependencyType type = DependencyType.finishToStart,
    int lagDays = 0,
  }) {
    // Validate that adding this dependency won't create a cycle
    final existingGraph = _buildDependencyGraph();
    final validationResult = DependencyValidator.validateDependency(
      prerequisiteId: prerequisiteId,
      dependentId: dependentId,
      existingDependencies: existingGraph,
    );

    if (validationResult.hasCycle) {
      return validationResult;
    }

    // Valid dependency - add it
    final key = _makeKey(prerequisiteId, dependentId);
    final dependency = TaskDependency(
      prerequisiteId: prerequisiteId,
      dependentId: dependentId,
      type: type,
      lagDays: lagDays,
    );

    state = {...state, key: dependency};

    // Update the task's dependencies list
    _updateTaskDependencies(dependentId, prerequisiteId, add: true);

    return validationResult;
  }

  /// Removes a dependency between tasks.
  void removeDependency({
    required String prerequisiteId,
    required String dependentId,
  }) {
    final key = _makeKey(prerequisiteId, dependentId);
    final newState = Map<String, TaskDependency>.from(state);
    newState.remove(key);
    state = newState;

    // Update the task's dependencies list
    _updateTaskDependencies(dependentId, prerequisiteId, add: false);
  }

  /// Updates a dependency's properties.
  void updateDependency({
    required String prerequisiteId,
    required String dependentId,
    DependencyType? type,
    int? lagDays,
  }) {
    final key = _makeKey(prerequisiteId, dependentId);
    final existing = state[key];
    if (existing == null) return;

    final updated = existing.copyWith(
      type: type,
      lagDays: lagDays,
    );

    state = {...state, key: updated};
  }

  /// Gets all dependencies for a specific task (as a dependent).
  List<TaskDependency> getDependenciesForTask(String taskId) {
    return state.values.where((dep) => dep.dependentId == taskId).toList();
  }

  /// Gets all tasks that depend on a specific task (as a prerequisite).
  List<TaskDependency> getDependentsForTask(String taskId) {
    return state.values.where((dep) => dep.prerequisiteId == taskId).toList();
  }

  /// Validates all current dependencies for cycles.
  CycleDetectionResult validateAll() {
    final graph = _buildDependencyGraph();
    return DependencyValidator.validateAllDependencies(graph);
  }

  /// Builds a dependency graph from current state.
  Map<String, List<String>> _buildDependencyGraph() {
    final graph = <String, List<String>>{};

    for (final dep in state.values) {
      graph.putIfAbsent(dep.prerequisiteId, () => []).add(dep.dependentId);
    }

    return graph;
  }

  /// Updates the task's dependencies list in the matrix controller.
  void _updateTaskDependencies(
    String taskId,
    String prerequisiteId, {
    required bool add,
  }) {
    final controller = ref.read(matrixControllerProvider.notifier);

    controller.updateTask(taskId, (task) {
      final currentDeps = List<String>.from(task.dependencies);

      if (add) {
        if (!currentDeps.contains(prerequisiteId)) {
          currentDeps.add(prerequisiteId);
        }
      } else {
        currentDeps.remove(prerequisiteId);
      }

      return task.copyWith(dependencies: currentDeps);
    });
  }

  /// Removes all dependencies for a task (used when deleting a task).
  void removeDependenciesForTask(String taskId) {
    final newState = Map<String, TaskDependency>.from(state);

    // Remove all dependencies where task is either prerequisite or dependent
    newState.removeWhere((key, dep) =>
        dep.prerequisiteId == taskId || dep.dependentId == taskId);

    state = newState;
  }
}

final dependenciesControllerProvider =
    NotifierProvider<DependenciesController, Map<String, TaskDependency>>(
  DependenciesController.new,
);

/// Provider for getting dependency arrows ready for rendering.
///
/// Converts TaskDependency objects into visual arrow specifications
/// with computed screen coordinates.
final dependencyArrowsProvider = Provider<List<TaskDependency>>((ref) {
  final dependencies = ref.watch(dependenciesControllerProvider);
  return dependencies.values.toList();
});

/// Provider for getting tasks involved in dependencies.
final tasksWithDependenciesProvider = Provider<Set<String>>((ref) {
  final dependencies = ref.watch(dependenciesControllerProvider);
  final taskIds = <String>{};

  for (final dep in dependencies.values) {
    taskIds.add(dep.prerequisiteId);
    taskIds.add(dep.dependentId);
  }

  return taskIds;
});
