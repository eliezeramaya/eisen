import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/focus/data/focus_repository.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scoring_service.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';
import 'package:eisen/features/stats/application/stats_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Task buildTask({
  required String id,
  Quadrant quadrant = Quadrant.q2,
  int priority = 5,
  int minutes = 30,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  String? category,
}) {
  return Task(
    id: id,
    title: id,
    quadrant: quadrant,
    priority: priority,
    minutes: minutes,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
    category: category,
  );
}

class FakeMatrixController extends Notifier<MatrixState> {
  FakeMatrixController(this._tasks);
  final List<Task> _tasks;

  @override
  MatrixState build() {
    return MatrixState(
      tasks: _tasks,
      presentQuadrant: Quadrant.q2,
    );
  }
}

class FakeFocusRepository implements FocusRepository {
  FakeFocusRepository(this.sessions);
  final List<FocusSession> sessions;

  @override
  Future<void> saveSession(FocusSession session) async {}

  @override
  Future<List<FocusSession>> getSessions({
    DateTime? from,
    DateTime? to,
    FocusSessionType? type,
  }) async {
    return sessions.where((s) {
      if (type != null && s.type != type) return false;
      final afterFrom = from == null || s.startedAt.isAfter(from);
      final beforeTo = to == null || s.startedAt.isBefore(to);
      return afterFrom && beforeTo;
    }).toList();
  }

  @override
  Future<int> getTodayCount(FocusSessionType type) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (await getSessions(from: start, to: end, type: type)).length;
  }

  @override
  Future<Duration> getTodayFocusTime() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final todays = await getSessions(from: start, to: end);
    return todays.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + (s.actualDuration ?? s.plannedDuration),
    );
  }

  @override
  Future<Map<DateTime, List<FocusSession>>> getRecentHistory({
    int days = 7,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
    final map = <DateTime, List<FocusSession>>{};
    for (final s in sessions) {
      if (s.startedAt.isBefore(start)) continue;
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }
}

class StubProductivityScoringService implements ProductivityScoringService {
  const StubProductivityScoringService({
    this.scoreFactory,
    this.focusWindows = const [],
  });

  final List<DailyProductivityScore> Function(DateTime from, DateTime to)?
      scoreFactory;
  final List<FocusWindowSuggestion> focusWindows;

  @override
  Future<List<DailyProductivityScore>> computeDailyScores({
    required DateTime from,
    required DateTime to,
  }) async {
    if (scoreFactory != null) {
      return scoreFactory!(from, to);
    }
    return [];
  }

  @override
  Future<List<FocusWindowSuggestion>> computeFocusWindows({
    required DateTime from,
    required DateTime to,
  }) async {
    return focusWindows;
  }
}

ProviderContainer buildStatsContainer({
  List<Task> tasks = const [],
  List<FocusSession> sessions = const [],
  ProductivityScoringService scoring = const StubProductivityScoringService(),
}) {
  return ProviderContainer(
    overrides: [
      matrixControllerProvider.overrideWith(
        () => FakeMatrixController(tasks),
      ),
      focusRepositoryProvider.overrideWithValue(
        FakeFocusRepository(sessions),
      ),
      productivityScoringServiceProvider.overrideWithValue(scoring),
    ],
  );
}
