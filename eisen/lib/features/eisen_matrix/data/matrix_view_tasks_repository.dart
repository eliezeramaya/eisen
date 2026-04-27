import '../domain/entities.dart';
import '../domain/matrix_view_filter.dart';

import 'local_repo.dart';

/// Repository for matrix view task queries (space + time filters).
///
/// Provides a high-level API to obtain tasks for a given [MatrixViewFilter].
/// For real-time UI, prefer using [getTasksForMatrix] together with
/// [matrixTasksProvider] from the main matrix controller.
class MatrixViewTasksRepository {
  MatrixViewTasksRepository(this._matrixRepository);

  final MatrixRepository _matrixRepository;

  /// Watch tasks for a given [filter] using the persisted task storage.
  ///
  /// This is a convenience stream that emits the current snapshot once.
  /// It does not automatically track in-memory changes managed by
  /// [MatrixController]; callers integrating with Riverpod should instead
  /// use [getTasksForMatrix] combined with `matrixTasksProvider`.
  Stream<List<Task>> watchTasksForMatrix(MatrixViewFilter filter) async* {
    final all = await _matrixRepository.load();
    yield getTasksForMatrix(allTasks: all, filter: filter);
  }

  /// Apply focus space + time + completion filters to [allTasks].
  List<Task> getTasksForMatrix({
    required List<Task> allTasks,
    required MatrixViewFilter filter,
  }) {
    final space = filter.focusSpace;
    Iterable<Task> tasks = allTasks;

    // Category filter: General (categoryId == null) shows all tasks.
    final categoryId = space.categoryId;
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      final needle = categoryId.trim().toLowerCase();
      tasks = tasks.where((t) {
        final cat = t.categoryId ?? t.category;
        return cat != null && cat.trim().toLowerCase() == needle;
      });
    }

    // Completed vs active filter.
    if (filter.onlyCompleted) {
      tasks = tasks.where((t) => t.completedAt != null);
    } else {
      tasks = tasks.where((t) => t.completedAt == null);
    }

    // Time filter: when "all", do not restrict by date.
    if (filter.timeFilter != MatrixTimeFilterType.all) {
      final range = filter.getDateRange();
      if (filter.onlyCompleted) {
        tasks = tasks.where((t) {
          final completedAt = t.completedAt;
          if (completedAt == null) return false;
          return !completedAt.isBefore(range.start) &&
              completedAt.isBefore(range.end);
        });
      } else {
        tasks = tasks.where((t) {
          final createdAt = t.createdAt;
          if (createdAt == null) return true; // include legacy tasks
          return !createdAt.isBefore(range.start) &&
              createdAt.isBefore(range.end);
        });
      }
    }

    return tasks.toList(growable: false);
  }
}
