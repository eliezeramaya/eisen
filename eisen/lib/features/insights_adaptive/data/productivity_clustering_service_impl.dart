import 'package:eisen/core/analytics/user_behavior_service.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:eisen/features/insights_adaptive/domain/clustering_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Implementación heurística basada en snapshots semanales.
class ProductivityClusteringServiceImpl
    implements ProductivityClusteringService {
  ProductivityClusteringServiceImpl({required this.behaviorService});

  final UserBehaviorService behaviorService;

  @override
  Future<UserProductivityProfile> computeWeeklyProfile(DateTime now) async {
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 7));
    final snaps = await behaviorService.getDailySnapshots(from: start, to: end);
    if (snaps.isEmpty) {
      return UserProductivityProfile(
        cluster: ProductivityCluster.unknown,
        computedAt: now,
      );
    }

    // Señales heurísticas
    final totalFocusMinutes =
        snaps.fold<int>(0, (sum, s) => sum + s.totalFocusDuration.inMinutes);
    final avgFocus =
        totalFocusMinutes == 0 ? 0.0 : totalFocusMinutes / snaps.length;

    final lateNightWork = snaps.fold<int>(0, (sum, s) {
      // Proxy: nudgesShown used? fallback to tasksCompletedQ1 as urgent indicator
      return sum + s.tasksCompletedQ1;
    });

    final totalCreated =
        snaps.fold<int>(0, (sum, s) => sum + s.tasksCreated);
    final totalCompleted =
        snaps.fold<int>(0, (sum, s) => sum + s.tasksCompleted);
    final totalRescheduled =
        snaps.fold<int>(0, (sum, s) => sum + s.tasksRescheduled);
    final replanRatio =
        totalCreated == 0 ? 0.0 : totalRescheduled / totalCreated;
    final completionRatio =
        totalCreated == 0 ? 0.0 : totalCompleted / totalCreated;

    // Morning focus proxy: if average focus >0 and focusSessionsCount high
    final morningBias = snaps.any((s) => s.focusSessionsCount >= 2);

    ProductivityCluster cluster = ProductivityCluster.unknown;
    if (lateNightWork >= totalCompleted * 0.6 && replanRatio < 0.4) {
      cluster = ProductivityCluster.nightSprinter;
    } else if (morningBias && avgFocus > 45 && completionRatio > 0.5) {
      cluster = ProductivityCluster.morningStrong;
    } else if (completionRatio < 0.4 && replanRatio > 0.4) {
      cluster = ProductivityCluster.starterButNotFinisher;
    }

    return UserProductivityProfile(cluster: cluster, computedAt: now);
  }
}

final productivityClusteringServiceProvider =
    Provider<ProductivityClusteringService>((ref) {
  final behavior = ref.watch(userBehaviorServiceProvider);
  return ProductivityClusteringServiceImpl(behaviorService: behavior);
});
