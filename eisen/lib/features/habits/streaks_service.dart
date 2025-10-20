import 'package:eisen/features/eisen_matrix/domain/entities.dart';

/// Computes streaks (consecutive active days) based on task completions.
class StreaksService {
  /// Returns number of consecutive days (ending today) with at least one
  /// completion (completedAt set) in [tasks].
  int streakDays(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final today = DateTime.now();
    int days = 0;
    DateTime cursor = DateTime(today.year, today.month, today.day);
    while (true) {
      final dayStart = cursor;
      final dayEnd = dayStart.add(const Duration(days: 1));
      final has = tasks.any((t) {
        final c = t.completedAt;
        return c != null && c.isAfter(dayStart) && c.isBefore(dayEnd);
      });
      if (has) {
        days += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return days;
  }
}

