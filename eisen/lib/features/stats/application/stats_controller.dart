import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repo.dart';
import '../domain/models.dart';

final statsRepoProvider = Provider<StatsRepo>(StatsRepo.new);

/// Controller for the currently selected time range in the Stats dashboard.
class StatsRangeController extends Notifier<StatsRange> {
  @override
  StatsRange build() => StatsRange.last7Days;

  void set(StatsRange value) {
    state = value;
  }
}

final statsRangeProvider =
    NotifierProvider<StatsRangeController, StatsRange>(StatsRangeController.new);

/// Controller for the currently selected project in the Stats dashboard.
class StatsProjectController extends Notifier<ProjectCategory> {
  @override
  ProjectCategory build() => ProjectCategory.all;

  void set(ProjectCategory value) {
    state = value;
  }
}

final statsProjectProvider =
    NotifierProvider<StatsProjectController, ProjectCategory>(
        StatsProjectController.new);

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final repo = ref.read(statsRepoProvider);
  final range = ref.watch(statsRangeProvider);
  final project = ref.watch(statsProjectProvider);
  return repo.computeStats(range, project, DateTime.now());
});

final streakProvider = Provider<int>((ref) {
  final repo = ref.read(statsRepoProvider);
  return repo.currentStreak();
});

final balanceProvider = FutureProvider<BalanceBreakdown>((ref) async {
  final repo = ref.read(statsRepoProvider);
  final range = ref.watch(statsRangeProvider);
  final project = ref.watch(statsProjectProvider);
  return repo.rangeBalance(range, project, DateTime.now());
});

final trendsProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final repo = ref.read(statsRepoProvider);
  final range = ref.watch(statsRangeProvider);
  final project = ref.watch(statsProjectProvider);
  return repo.focusTrend(range: range, project: project);
});
