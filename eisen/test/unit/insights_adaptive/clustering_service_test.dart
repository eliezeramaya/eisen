import 'package:eisen/core/analytics/user_behavior_service.dart';
import 'package:eisen/core/analytics/user_behavior_snapshot.dart';
import 'package:eisen/features/insights_adaptive/data/productivity_clustering_service_impl.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBehavior implements UserBehaviorService {
  _FakeBehavior(this.snaps);
  final List<UserBehaviorSnapshot> snaps;

  @override
  Future<List<UserBehaviorSnapshot>> getDailySnapshots({
    required DateTime from,
    required DateTime to,
  }) async =>
      snaps;
}

void main() {
  test('Clustering detects starter-but-not-finisher', () async {
    final behavior = _FakeBehavior([
      UserBehaviorSnapshot(
        day: DateTime(2025, 1, 9),
        tasksCreated: 10,
        tasksCompleted: 2,
        tasksRescheduled: 6,
      ),
    ]);
    final svc = ProductivityClusteringServiceImpl(behaviorService: behavior);
    final profile = await svc.computeWeeklyProfile(DateTime(2025, 1, 10));
    expect(profile.cluster, ProductivityCluster.starterButNotFinisher);
  });
}
