import 'package:eisen/features/focus/domain/focus_session.dart';

/// Repository interface for persisting focus sessions
abstract class FocusRepository {
  /// Save a completed focus session
  Future<void> saveSession(FocusSession session);

  /// Get all focus sessions within date range
  Future<List<FocusSession>> getSessions({
    DateTime? from,
    DateTime? to,
    FocusSessionType? type,
  });

  /// Get count of sessions completed today for a specific type
  Future<int> getTodayCount(FocusSessionType type);

  /// Get total focus time today across all types
  Future<Duration> getTodayFocusTime();

  /// Get session history for the last N days
  Future<Map<DateTime, List<FocusSession>>> getRecentHistory({
    int days = 7,
  });
}
