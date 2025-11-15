import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/completed_tasks/domain/filters.dart';
import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/completed_tasks/data/completed_tasks_repository.dart';

/// Immutable state for completed tasks matrix view.
///
/// Contains:
/// - Filter configuration
/// - Filtered task list
/// - Loading state
/// - UI state (zoom, selection)
/// - Statistics
class CompletedMatrixState {
  const CompletedMatrixState({
    required this.filter,
    this.tasks = const [],
    this.isLoading = false,
    this.zoomFactor = 1.0,
    this.selectedTaskId,
    this.stats,
  });

  final CompletedTasksFilter filter;
  final List<Task> tasks;
  final bool isLoading;
  final double zoomFactor; // 0.7 - 1.4 range
  final String? selectedTaskId;
  final CompletedTasksStats? stats;

  /// Divide tasks by quadrant for matrix layout
  List<Task> get q1Tasks =>
      tasks.where((t) => t.quadrant == Quadrant.q1).toList();
  List<Task> get q2Tasks =>
      tasks.where((t) => t.quadrant == Quadrant.q2).toList();
  List<Task> get q3Tasks =>
      tasks.where((t) => t.quadrant == Quadrant.q3).toList();
  List<Task> get q4Tasks =>
      tasks.where((t) => t.quadrant == Quadrant.q4).toList();

  /// Check if any quadrant has tasks
  bool get hasAnyTasks => tasks.isNotEmpty;

  /// Check if filter is set to "all" (potentially many tasks)
  bool get isShowingAll => filter.timeType == TimeFilterType.all;

  CompletedMatrixState copyWith({
    CompletedTasksFilter? filter,
    List<Task>? tasks,
    bool? isLoading,
    double? zoomFactor,
    String? selectedTaskId,
    bool clearSelection = false,
    CompletedTasksStats? stats,
  }) {
    return CompletedMatrixState(
      filter: filter ?? this.filter,
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      zoomFactor: zoomFactor ?? this.zoomFactor,
      selectedTaskId:
          clearSelection ? null : (selectedTaskId ?? this.selectedTaskId),
      stats: stats ?? this.stats,
    );
  }
}

/// Controller for completed tasks matrix.
///
/// Manages:
/// - Filter state updates
/// - Task loading and filtering
/// - Zoom factor
/// - Task selection
///
/// Automatically reloads tasks when filter or source tasks change.
class CompletedMatrixController extends Notifier<CompletedMatrixState> {
  late final CompletedTasksRepository _repository;

  @override
  CompletedMatrixState build() {
    _repository = CompletedTasksRepository();

    // Initialize with year filter for current date
    final now = DateTime.now();
    final initialFilter = CompletedTasksFilter(
      timeType: TimeFilterType.year,
      referenceDate: now,
    );

    // Load tasks on init
    Future.microtask(() => _loadTasks());

    return CompletedMatrixState(filter: initialFilter);
  }

  /// Update time filter type
  void updateTimeFilter(TimeFilterType type) {
    final newFilter = state.filter.copyWith(timeType: type);
    state = state.copyWith(filter: newFilter, isLoading: true);
    _loadTasks();
  }

  /// Update reference date (for year/month/week/day selection)
  void updateReferenceDate(DateTime date) {
    final newFilter = state.filter.copyWith(referenceDate: date);
    state = state.copyWith(filter: newFilter, isLoading: true);
    _loadTasks();
  }

  /// Update project filter
  void updateProject(ProjectCategory? project) {
    final newFilter = state.filter.copyWith(
      project: project,
      clearProject: project == null || project == ProjectCategory.all,
    );
    state = state.copyWith(filter: newFilter, isLoading: true);
    _loadTasks();
  }

  /// Set zoom factor (0.7 - 1.4)
  void setZoomFactor(double factor) {
    final clamped = factor.clamp(0.7, 1.4);
    state = state.copyWith(zoomFactor: clamped);
  }

  /// Select a task (or null to deselect)
  void selectTask(String? id) {
    state = state.copyWith(
      selectedTaskId: id,
      clearSelection: id == null,
    );
  }

  /// Load tasks from main controller with current filter
  Future<void> _loadTasks() async {
    // Get all tasks from main matrix controller
    final allTasks = ref.read(matrixTasksProvider);

    // Apply filter
    final filtered = _repository.getCompletedTasks(
      allTasks: allTasks,
      filter: state.filter,
    );

    // Compute stats
    final stats = _repository.getStats(
      allTasks: allTasks,
      filter: state.filter,
    );

    state = state.copyWith(
      tasks: filtered,
      stats: stats,
      isLoading: false,
    );
  }

  /// Refresh tasks (call after main controller updates)
  void refresh() => _loadTasks();

  /// Navigate to next period (year/month/week/day)
  void nextPeriod() {
    final current = state.filter.referenceDate;
    final next = switch (state.filter.timeType) {
      TimeFilterType.all => current, // No change for "all"
      TimeFilterType.year =>
        DateTime(current.year + 1, current.month, current.day),
      TimeFilterType.month =>
        DateTime(current.year, current.month + 1, current.day),
      TimeFilterType.week => current.add(const Duration(days: 7)),
      TimeFilterType.day => current.add(const Duration(days: 1)),
    };
    updateReferenceDate(next);
  }

  /// Navigate to previous period
  void previousPeriod() {
    final current = state.filter.referenceDate;
    final prev = switch (state.filter.timeType) {
      TimeFilterType.all => current, // No change for "all"
      TimeFilterType.year =>
        DateTime(current.year - 1, current.month, current.day),
      TimeFilterType.month =>
        DateTime(current.year, current.month - 1, current.day),
      TimeFilterType.week => current.subtract(const Duration(days: 7)),
      TimeFilterType.day => current.subtract(const Duration(days: 1)),
    };
    updateReferenceDate(prev);
  }

  /// Reset to current period (today)
  void resetToToday() {
    updateReferenceDate(DateTime.now());
  }
}

/// Main provider for completed matrix controller
final completedMatrixProvider =
    NotifierProvider<CompletedMatrixController, CompletedMatrixState>(
  CompletedMatrixController.new,
);

/// Selector providers for optimized rebuilds
final completedTasksFilterProvider = Provider<CompletedTasksFilter>(
  (ref) => ref.watch(completedMatrixProvider.select((s) => s.filter)),
);

final completedTasksListProvider = Provider<List<Task>>(
  (ref) => ref.watch(completedMatrixProvider.select((s) => s.tasks)),
);

final completedTasksLoadingProvider = Provider<bool>(
  (ref) => ref.watch(completedMatrixProvider.select((s) => s.isLoading)),
);

final completedZoomFactorProvider = Provider<double>(
  (ref) => ref.watch(completedMatrixProvider.select((s) => s.zoomFactor)),
);

final completedStatsProvider = Provider<CompletedTasksStats?>(
  (ref) => ref.watch(completedMatrixProvider.select((s) => s.stats)),
);
