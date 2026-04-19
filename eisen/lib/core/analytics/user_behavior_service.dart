import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'user_behavior_snapshot.dart';
import 'user_event.dart';

abstract class UserBehaviorService {
  Future<List<UserBehaviorSnapshot>> getDailySnapshots({
    required DateTime from,
    required DateTime to,
  });
}

/// Implementación que consume eventos de [AnalyticsService] y los agrupa por día.
class DefaultUserBehaviorService implements UserBehaviorService {
  DefaultUserBehaviorService(this._analytics);

  final AnalyticsService _analytics;

  @override
  Future<List<UserBehaviorSnapshot>> getDailySnapshots({
    required DateTime from,
    required DateTime to,
  }) async {
    // Normalizar fechas a inicio de día para límites inclusivos.
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));

    final events = await _analytics.getEvents(from: start, to: end);
    if (events.isEmpty) return const [];

    // Agrupar por día normalizado.
    final Map<DateTime, UserBehaviorSnapshot> byDay = {};

    DateTime normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    UserBehaviorSnapshot ensure(DateTime day) {
      return byDay.putIfAbsent(
        day,
        () => UserBehaviorSnapshot(day: day),
      );
    }

    for (final e in events) {
      final day = normalize(e.timestamp);
      final snap = ensure(day);
      switch (e.type) {
        case UserEventType.taskCreated:
          byDay[day] = snap.copyWith(tasksCreated: snap.tasksCreated + 1);
          break;
        case UserEventType.taskCompleted:
          final quadrant = e.metadata['quadrant'] as String?;
          byDay[day] = snap.copyWith(
            tasksCompleted: snap.tasksCompleted + 1,
            tasksCompletedQ1:
                snap.tasksCompletedQ1 + (quadrant == 'q1' ? 1 : 0),
            tasksCompletedQ2:
                snap.tasksCompletedQ2 + (quadrant == 'q2' ? 1 : 0),
            tasksCompletedQ3:
                snap.tasksCompletedQ3 + (quadrant == 'q3' ? 1 : 0),
            tasksCompletedQ4:
                snap.tasksCompletedQ4 + (quadrant == 'q4' ? 1 : 0),
          );
          break;
        case UserEventType.taskRescheduled:
          byDay[day] =
              snap.copyWith(tasksRescheduled: snap.tasksRescheduled + 1);
          break;
        case UserEventType.focusSessionStarted:
          byDay[day] = snap.copyWith(
            focusSessionsCount: snap.focusSessionsCount + 1,
          );
          break;
        case UserEventType.focusSessionEnded:
          final minutes = (e.metadata['actualMinutes'] as num?)
                  ?.toDouble()
                  .toInt() ??
              (e.metadata['plannedMinutes'] as num?)?.toInt() ??
              0;
          byDay[day] = snap.copyWith(
            totalFocusDuration: snap.totalFocusDuration +
                Duration(minutes: minutes),
          );
          break;
        case UserEventType.nudgeShown:
          byDay[day] = snap.copyWith(nudgesShown: snap.nudgesShown + 1);
          break;
        case UserEventType.nudgeActionExecuted:
          byDay[day] = snap.copyWith(nudgesActed: snap.nudgesActed + 1);
          break;
        case UserEventType.appOpened:
        case UserEventType.appClosed:
          // Ignorados por ahora.
          break;
      }
    }

    final snapshots = byDay.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return snapshots;
  }
}

final userBehaviorServiceProvider = Provider<UserBehaviorService>(
  (ref) => DefaultUserBehaviorService(ref.read(analyticsServiceProvider)),
);
