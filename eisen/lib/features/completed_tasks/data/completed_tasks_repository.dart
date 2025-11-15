import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/completed_tasks/domain/filters.dart';
import 'package:eisen/features/completed_tasks/domain/project_category.dart';

/// Repository for completed tasks operations.
///
/// Provides filtered access to completed tasks from the main task list.
/// Applies time range and project filters efficiently.
class CompletedTasksRepository {
  /// Get completed tasks matching the filter.
  ///
  /// Filters applied in order:
  /// 1. Only tasks with non-null [completedAt]
  /// 2. Time range filter based on [filter.timeType]
  /// 3. Project filter if specified
  ///
  /// Returns: List sorted by [completedAt] descending (newest first)
  List<Task> getCompletedTasks({
    required List<Task> allTasks,
    required CompletedTasksFilter filter,
  }) {
    // Step 1: Filter completed tasks only
    final completed = allTasks.where((t) => t.completedAt != null);

    // Step 2: Apply time range filter
    final range = filter.getDateRange();
    final inRange = completed.where((t) {
      final completedAt = t.completedAt!;
      return completedAt.isAfter(range.start) &&
          completedAt.isBefore(range.end);
    });

    // Step 3: Apply project filter if specified
    final filtered = _applyProjectFilter(inRange, filter.project);

    // Step 4: Sort by completion date descending
    final sorted = filtered.toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    return sorted;
  }

  /// Apply project category filter to tasks
  Iterable<Task> _applyProjectFilter(
    Iterable<Task> tasks,
    ProjectCategory? project,
  ) {
    // No filter or "all" means include everything
    if (project == null || project == ProjectCategory.all) {
      return tasks;
    }

    // Match by category string
    final targetCategory = project.displayName;
    return tasks.where((t) =>
        t.category != null &&
        t.category!.toLowerCase() == targetCategory.toLowerCase());
  }

  /// Get statistics for completed tasks in filter range
  CompletedTasksStats getStats({
    required List<Task> allTasks,
    required CompletedTasksFilter filter,
  }) {
    final completed = getCompletedTasks(
      allTasks: allTasks,
      filter: filter,
    );

    final byQuadrant = {
      Quadrant.q1: completed.where((t) => t.quadrant == Quadrant.q1).length,
      Quadrant.q2: completed.where((t) => t.quadrant == Quadrant.q2).length,
      Quadrant.q3: completed.where((t) => t.quadrant == Quadrant.q3).length,
      Quadrant.q4: completed.where((t) => t.quadrant == Quadrant.q4).length,
    };

    final totalMinutes = completed.fold<int>(
      0,
      (sum, task) => sum + task.minutes,
    );

    return CompletedTasksStats(
      total: completed.length,
      q1Count: byQuadrant[Quadrant.q1]!,
      q2Count: byQuadrant[Quadrant.q2]!,
      q3Count: byQuadrant[Quadrant.q3]!,
      q4Count: byQuadrant[Quadrant.q4]!,
      totalMinutes: totalMinutes,
    );
  }
}

/// Statistics for completed tasks in a given filter range
class CompletedTasksStats {
  const CompletedTasksStats({
    required this.total,
    required this.q1Count,
    required this.q2Count,
    required this.q3Count,
    required this.q4Count,
    required this.totalMinutes,
  });

  final int total;
  final int q1Count;
  final int q2Count;
  final int q3Count;
  final int q4Count;
  final int totalMinutes;

  /// Total hours (rounded)
  int get totalHours => (totalMinutes / 60).round();

  /// Check if any quadrant has tasks
  bool get hasAnyTasks => total > 0;

  /// Balance percentage for a quadrant (0-100)
  double balancePercent(Quadrant q) {
    if (total == 0) return 0.0;
    final count = switch (q) {
      Quadrant.q1 => q1Count,
      Quadrant.q2 => q2Count,
      Quadrant.q3 => q3Count,
      Quadrant.q4 => q4Count,
    };
    return (count / total) * 100.0;
  }
}
