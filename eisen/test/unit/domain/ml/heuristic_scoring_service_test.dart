import 'package:eisen/core/analytics/analytics_service.dart';
import 'package:eisen/core/analytics/user_behavior_service.dart';
import 'package:eisen/core/analytics/user_behavior_snapshot.dart';
import 'package:eisen/core/analytics/user_event.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalytics implements AnalyticsService {
  _FakeAnalytics(this.events);
  final List<UserEvent> events;

  @override
  Future<void> clear() async {}

  @override
  Future<List<UserEvent>> getEvents({DateTime? from, DateTime? to}) async {
    return events.where((e) {
      final after = from == null || !e.timestamp.isBefore(from);
      final before = to == null || e.timestamp.isBefore(to);
      return after && before;
    }).toList();
  }

  @override
  Future<void> logEvent(UserEvent event) async {}
}

class _FakeBehavior implements UserBehaviorService {
  _FakeBehavior(this.snapshots);
  final List<UserBehaviorSnapshot> snapshots;

  @override
  Future<List<UserBehaviorSnapshot>> getDailySnapshots({
    required DateTime from,
    required DateTime to,
  }) async {
    return snapshots
        .where((s) =>
            !s.day.isBefore(DateTime(from.year, from.month, from.day)) &&
            s.day.isBefore(
                DateTime(to.year, to.month, to.day).add(const Duration(days: 1))))
        .toList();
  }
}

void main() {
  group('HeuristicProductivityScoringService', () {
    final now = DateTime(2025, 1, 10, 9);
    final analytics = _FakeAnalytics([
      UserEvent(
        type: UserEventType.focusSessionEnded,
        timestamp: now,
        metadata: {'actualMinutes': 50},
      ),
      UserEvent(
        type: UserEventType.focusSessionEnded,
        timestamp: now.subtract(const Duration(hours: 3)),
        metadata: {'actualMinutes': 20},
      ),
    ]);
    final behavior = _FakeBehavior([
      UserBehaviorSnapshot(
        day: DateTime(2025, 1, 9),
        tasksCreated: 5,
        tasksCompleted: 3,
      ),
      UserBehaviorSnapshot(
        day: DateTime(2025, 1, 10),
        tasksCreated: 6,
        tasksCompleted: 2,
      ),
    ]);

    final service = HeuristicProductivityScoringService(
      behaviorService: behavior,
      analyticsService: analytics,
    );

    test('predictTaskCompletion adjusts by quadrant and replanCount', () async {
      final base = Task(
        id: 't1',
        title: 'Deep work',
        quadrant: Quadrant.q2,
        priority: 5,
        minutes: 60,
        replanCount: 0,
      );
      final prediction = await service.predictTaskCompletion(base);
      expect(prediction.onTimeProbability, closeTo(0.75, 0.1));

      final heavy = base.copyWith(
        quadrant: Quadrant.q4,
        replanCount: 3,
        minutes: 300,
      );
      final prediction2 = await service.predictTaskCompletion(heavy);
      expect(prediction2.onTimeProbability, lessThan(prediction.onTimeProbability));
      expect(prediction2.reprogramProbability,
          closeTo(1 - prediction2.onTimeProbability, 1e-6));
    });

    test('predictTaskProcrastination flags vague, long, Q4 tasks', () async {
      final task = Task(
        id: 't2',
        title: 'Revisar pendientes',
        quadrant: Quadrant.q4,
        priority: 3,
        minutes: 200,
        replanCount: 2,
      );
      final score = await service.predictTaskProcrastination(task);
      expect(score.value, greaterThan(0.7));
    });

    test('computeFocusWindows finds best hour bucket', () async {
      final windows = await service.computeFocusWindows(
        from: now.subtract(const Duration(days: 1)),
        to: now.add(const Duration(days: 1)),
      );
      expect(windows, isNotEmpty);
      // Highest duration/count bucket is hour 9 (50 minutes) vs hour 6 (20)
      expect(windows.first.start.hour, 9);
    });
  });
}
