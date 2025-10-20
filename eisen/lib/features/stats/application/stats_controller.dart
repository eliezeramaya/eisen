import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_repo.dart';
import '../domain/models.dart';

final statsRepoProvider = Provider<StatsRepo>((ref) => StatsRepo(ref));

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final repo = ref.read(statsRepoProvider);
  return repo.computeWeeklyStats(DateTime.now());
});

final streakProvider = Provider<int>((ref) {
  final repo = ref.read(statsRepoProvider);
  return repo.currentStreak();
});

final balanceProvider = FutureProvider<BalanceBreakdown>((ref) async {
  final repo = ref.read(statsRepoProvider);
  return repo.weeklyBalance(DateTime.now());
});

final trendsProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final repo = ref.read(statsRepoProvider);
  return repo.focusTrend(days: 14);
});

