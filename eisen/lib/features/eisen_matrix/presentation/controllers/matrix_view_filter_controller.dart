import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/eisen_matrix/data/local_repo.dart';
import 'package:eisen/features/eisen_matrix/data/matrix_view_tasks_repository.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/focus_space.dart';
import 'package:eisen/features/eisen_matrix/domain/matrix_view_filter.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for the active matrix view filter (focus space + time window).
class MatrixViewFilterController extends Notifier<MatrixViewFilter> {
  @override
  MatrixViewFilter build() {
    // Default: General space, no time restriction, show active tasks.
    return MatrixViewFilter(
      focusSpace: FocusSpace.general,
      timeFilter: MatrixTimeFilterType.all,
      referenceDate: DateTime.now(),
      onlyCompleted: false,
    );
  }

  void setFocusSpace(FocusSpace space) {
    state = state.copyWith(focusSpace: space);
  }

  void setTimeFilter(MatrixTimeFilterType type) {
    state = state.copyWith(timeFilter: type);
  }

  void setOnlyCompleted(bool onlyCompleted) {
    state = state.copyWith(onlyCompleted: onlyCompleted);
  }

  void updateReferenceDate(DateTime date) {
    state = state.copyWith(referenceDate: date);
  }

  void resetToToday() {
    updateReferenceDate(DateTime.now());
  }

  void nextPeriod() {
    final current = state.referenceDate;
    final next = switch (state.timeFilter) {
      MatrixTimeFilterType.all => current,
      MatrixTimeFilterType.year => DateTime(
        current.year + 1,
        current.month,
        current.day,
      ),
      MatrixTimeFilterType.month => DateTime(
        current.year,
        current.month + 1,
        current.day,
      ),
      MatrixTimeFilterType.week => current.add(const Duration(days: 7)),
      MatrixTimeFilterType.today => current.add(const Duration(days: 1)),
    };
    updateReferenceDate(next);
  }

  void previousPeriod() {
    final current = state.referenceDate;
    final prev = switch (state.timeFilter) {
      MatrixTimeFilterType.all => current,
      MatrixTimeFilterType.year => DateTime(
        current.year - 1,
        current.month,
        current.day,
      ),
      MatrixTimeFilterType.month => DateTime(
        current.year,
        current.month - 1,
        current.day,
      ),
      MatrixTimeFilterType.week => current.subtract(const Duration(days: 7)),
      MatrixTimeFilterType.today => current.subtract(const Duration(days: 1)),
    };
    updateReferenceDate(prev);
  }
}

/// Provider for the active matrix view filter state.
final matrixViewFilterProvider =
    NotifierProvider<MatrixViewFilterController, MatrixViewFilter>(
      MatrixViewFilterController.new,
    );

/// Internal provider for the tasks view repository that applies space + time
/// filters over the main task list.
final matrixViewTasksRepositoryProvider = Provider<MatrixViewTasksRepository>((
  ref,
) {
  final repo = LocalPrefsMatrixRepository(StoragePrefs());
  return MatrixViewTasksRepository(repo);
});

/// Provider exposing the list of tasks filtered by the current
/// [MatrixViewFilter].
///
/// It reads from:
/// - [matrixTasksProvider]: all tasks managed by [MatrixController]
/// - [matrixViewFilterProvider]: current focus space + time window
final matrixFilteredTasksProvider = Provider<List<Task>>((ref) {
  final allTasks = ref.watch(matrixTasksProvider);
  final filter = ref.watch(matrixViewFilterProvider);
  final repo = ref.watch(matrixViewTasksRepositoryProvider);
  return repo.getTasksForMatrix(allTasks: allTasks, filter: filter);
});
