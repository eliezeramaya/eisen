import 'package:eisen/features/focus/data/focus_repository.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';
import 'package:flutter/foundation.dart';

/// Stub implementation of FocusRepository for development
/// Stores sessions in memory only
class FocusRepositoryStub implements FocusRepository {
  final List<FocusSession> _sessions = [];

  @override
  Future<void> saveSession(FocusSession session) async {
    _sessions.add(session);
    debugPrint(
      'Focus session saved: ${session.type.name}, '
      'duration: ${session.actualDuration ?? session.plannedDuration}',
    );
  }

  @override
  Future<List<FocusSession>> getSessions({
    DateTime? from,
    DateTime? to,
    FocusSessionType? type,
  }) async {
    var filtered = _sessions.toList();

    if (from != null) {
      filtered = filtered.where((s) => s.startedAt.isAfter(from)).toList();
    }

    if (to != null) {
      filtered = filtered.where((s) => s.startedAt.isBefore(to)).toList();
    }

    if (type != null) {
      filtered = filtered.where((s) => s.type == type).toList();
    }

    return filtered;
  }

  @override
  Future<int> getTodayCount(FocusSessionType type) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _sessions
        .where((s) =>
            s.type == type &&
            s.startedAt.isAfter(todayStart) &&
            s.startedAt.isBefore(todayEnd))
        .length;
  }

  @override
  Future<Duration> getTodayFocusTime() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todaySessions = _sessions.where(
      (s) => s.startedAt.isAfter(todayStart) && s.startedAt.isBefore(todayEnd),
    );

    var totalSeconds = 0;
    for (final session in todaySessions) {
      final duration = session.actualDuration ?? session.plannedDuration;
      totalSeconds += duration.inSeconds;
    }

    return Duration(seconds: totalSeconds);
  }

  @override
  Future<Map<DateTime, List<FocusSession>>> getRecentHistory({
    int days = 7,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final recentSessions = _sessions.where(
      (s) => s.startedAt.isAfter(startDate),
    );

    final history = <DateTime, List<FocusSession>>{};

    for (final session in recentSessions) {
      final date = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );

      if (history.containsKey(date)) {
        history[date]!.add(session);
      } else {
        history[date] = [session];
      }
    }

    return history;
  }

  /// Clear all sessions (for testing)
  void clear() {
    _sessions.clear();
  }
}
