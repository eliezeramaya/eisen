import 'package:eisen/core/analytics/analytics_service.dart';
import 'package:eisen/core/analytics/user_behavior_service.dart';
import 'package:eisen/core/analytics/user_behavior_snapshot.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:eisen/core/analytics/user_event.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalytics implements AnalyticsService {
  @override
  Future<void> clear() async {}

  @override
  Future<List<UserEvent>> getEvents({DateTime? from, DateTime? to}) async =>
      const [];

  @override
  Future<void> logEvent(UserEvent event) async {}
}

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
  test('computeDailyOverloadRisk scales with planned vs average', () async {
    final behavior = _FakeBehavior([
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 9), tasksCreated: 10),
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 8), tasksCompleted: 2),
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 7), tasksCompleted: 2),
    ]);
    final service = HeuristicProductivityScoringService(
      behaviorService: behavior,
      analyticsService: _FakeAnalytics(),
    );
    final risk =
        await service.computeDailyOverloadRisk(const DateTime(2025, 1, 9));
    expect(risk.score, greaterThan(0.6));

    final behaviorLow = _FakeBehavior([
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 9), tasksCreated: 1),
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 8), tasksCompleted: 3),
      const UserBehaviorSnapshot(day: const DateTime(2025, 1, 7), tasksCompleted: 3),
    ]);
    final lowService = HeuristicProductivityScoringService(
      behaviorService: behaviorLow,
      analyticsService: _FakeAnalytics(),
    );
    final lowRisk =
        await lowService.computeDailyOverloadRisk(const DateTime(2025, 1, 9));
    expect(lowRisk.score, lessThan(risk.score));
  });
}
