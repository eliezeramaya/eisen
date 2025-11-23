import 'package:flutter/foundation.dart';

/// Type of dependency relationship between tasks.
///
/// Determines how the dependent task's schedule relates to the prerequisite.
enum DependencyType {
  /// Finish-to-Start: Dependent task can start when prerequisite finishes.
  /// Most common dependency type.
  /// Example: "Write code" → "Test code"
  finishToStart,

  /// Start-to-Start: Dependent task can start when prerequisite starts.
  /// Used for parallel tasks that must begin together.
  /// Example: "Design UI" → "Write documentation"
  startToStart,

  /// Finish-to-Finish: Dependent task must finish when prerequisite finishes.
  /// Used for synchronized completion.
  /// Example: "Code feature" → "Update tests"
  finishToFinish,

  /// Start-to-Finish: Dependent task must finish when prerequisite starts.
  /// Rare, used for handoff scenarios.
  /// Example: "Night shift" → "Day shift"
  startToFinish,
}

/// Represents a dependency relationship between two tasks.
///
/// A dependency declares that [dependentId] has a scheduling constraint
/// based on [prerequisiteId]'s timeline, according to [type].
@immutable
class TaskDependency {
  const TaskDependency({
    required this.prerequisiteId,
    required this.dependentId,
    this.type = DependencyType.finishToStart,
    this.lagDays = 0,
  });

  /// The task that must be completed (or reach milestone) first.
  final String prerequisiteId;

  /// The task that depends on the prerequisite.
  final String dependentId;

  /// Type of dependency relationship.
  final DependencyType type;

  /// Optional lag time in days between the prerequisite and dependent.
  /// Positive = delay, Negative = lead time.
  /// Example: +2 days = dependent starts 2 days after prerequisite finishes.
  final int lagDays;

  TaskDependency copyWith({
    String? prerequisiteId,
    String? dependentId,
    DependencyType? type,
    int? lagDays,
  }) {
    return TaskDependency(
      prerequisiteId: prerequisiteId ?? this.prerequisiteId,
      dependentId: dependentId ?? this.dependentId,
      type: type ?? this.type,
      lagDays: lagDays ?? this.lagDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDependency &&
          runtimeType == other.runtimeType &&
          prerequisiteId == other.prerequisiteId &&
          dependentId == other.dependentId &&
          type == other.type &&
          lagDays == other.lagDays;

  @override
  int get hashCode =>
      prerequisiteId.hashCode ^
      dependentId.hashCode ^
      type.hashCode ^
      lagDays.hashCode;

  @override
  String toString() =>
      'TaskDependency($prerequisiteId → $dependentId, type: $type, lag: ${lagDays}d)';
}

/// Result of a cycle detection operation.
@immutable
class CycleDetectionResult {
  const CycleDetectionResult({
    required this.hasCycle,
    this.cycle = const [],
  });

  /// Whether a cycle was detected.
  final bool hasCycle;

  /// The path of task IDs forming the cycle, if any.
  /// Example: ['task1', 'task2', 'task3', 'task1']
  final List<String> cycle;

  bool get isValid => !hasCycle;

  String get cycleDescription {
    if (!hasCycle || cycle.isEmpty) return 'No cycle';
    return cycle.join(' → ');
  }

  @override
  String toString() =>
      hasCycle ? 'Cycle detected: $cycleDescription' : 'No cycle';
}

/// Service for validating task dependencies and detecting circular references.
class DependencyValidator {
  /// Detects if adding a new dependency would create a cycle.
  ///
  /// Uses depth-first search (DFS) to detect cycles in the dependency graph.
  ///
  /// Returns [CycleDetectionResult] with:
  /// - `hasCycle = true` and the cycle path if a cycle is detected
  /// - `hasCycle = false` if the dependency is valid
  static CycleDetectionResult validateDependency({
    required String prerequisiteId,
    required String dependentId,
    required Map<String, List<String>> existingDependencies,
  }) {
    // Create a temporary graph with the new dependency
    final graph = Map<String, List<String>>.from(existingDependencies);
    graph.putIfAbsent(prerequisiteId, () => []).add(dependentId);

    // Detect cycle starting from the dependent task
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    bool dfs(String taskId) {
      if (recursionStack.contains(taskId)) {
        // Found a cycle - reconstruct the cycle path
        final cycleStart = path.indexOf(taskId);
        path.clear();
        path.addAll(path.sublist(cycleStart)..add(taskId));
        return true;
      }

      if (visited.contains(taskId)) {
        return false; // Already fully explored this branch
      }

      visited.add(taskId);
      recursionStack.add(taskId);
      path.add(taskId);

      final dependencies = graph[taskId] ?? [];
      for (final depId in dependencies) {
        if (dfs(depId)) {
          return true; // Cycle found in recursive call
        }
      }

      recursionStack.remove(taskId);
      path.removeLast();
      return false;
    }

    // Start DFS from the prerequisite to check entire subgraph
    if (dfs(prerequisiteId)) {
      return CycleDetectionResult(hasCycle: true, cycle: List.from(path));
    }

    return const CycleDetectionResult(hasCycle: false);
  }

  /// Validates all dependencies in a task graph for cycles.
  ///
  /// Returns the first cycle found, or a valid result if no cycles exist.
  static CycleDetectionResult validateAllDependencies(
    Map<String, List<String>> dependencies,
  ) {
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    bool dfs(String taskId) {
      if (recursionStack.contains(taskId)) {
        final cycleStart = path.indexOf(taskId);
        final cyclePath = path.sublist(cycleStart)..add(taskId);
        path.clear();
        path.addAll(cyclePath);
        return true;
      }

      if (visited.contains(taskId)) return false;

      visited.add(taskId);
      recursionStack.add(taskId);
      path.add(taskId);

      final deps = dependencies[taskId] ?? [];
      for (final depId in deps) {
        if (dfs(depId)) return true;
      }

      recursionStack.remove(taskId);
      path.removeLast();
      return false;
    }

    // Check all tasks as potential cycle entry points
    for (final taskId in dependencies.keys) {
      if (!visited.contains(taskId)) {
        if (dfs(taskId)) {
          return CycleDetectionResult(hasCycle: true, cycle: List.from(path));
        }
      }
    }

    return const CycleDetectionResult(hasCycle: false);
  }

  /// Builds a dependency graph from a list of tasks.
  ///
  /// Returns a map where keys are task IDs and values are lists of
  /// dependent task IDs (tasks that depend on the key task).
  static Map<String, List<String>> buildDependencyGraph(
    List<dynamic> tasks,
    String Function(dynamic) getId,
    List<String> Function(dynamic) getDependencies,
  ) {
    final graph = <String, List<String>>{};

    for (final task in tasks) {
      final taskId = getId(task);
      final dependencies = getDependencies(task);

      // For each prerequisite this task depends on,
      // add this task to the prerequisite's dependents list
      for (final prerequisiteId in dependencies) {
        graph.putIfAbsent(prerequisiteId, () => []).add(taskId);
      }

      // Ensure the task exists in the graph even if it has no dependents
      graph.putIfAbsent(taskId, () => []);
    }

    return graph;
  }

  /// Computes topological sort of tasks based on dependencies.
  ///
  /// Returns tasks in an order such that all prerequisites come before
  /// their dependents. Returns null if a cycle is detected.
  static List<String>? topologicalSort(Map<String, List<String>> graph) {
    final result = <String>[];
    final visited = <String>{};
    final recursionStack = <String>{};

    bool dfs(String taskId) {
      if (recursionStack.contains(taskId)) return false; // Cycle detected
      if (visited.contains(taskId)) return true;

      visited.add(taskId);
      recursionStack.add(taskId);

      final dependents = graph[taskId] ?? [];
      for (final depId in dependents) {
        if (!dfs(depId)) return false;
      }

      recursionStack.remove(taskId);
      result.add(taskId);
      return true;
    }

    for (final taskId in graph.keys) {
      if (!visited.contains(taskId)) {
        if (!dfs(taskId)) return null; // Cycle detected
      }
    }

    return result.reversed.toList();
  }
}
