import 'package:flutter/foundation.dart';

/// Snapshot diario/semanal de comportamiento del usuario.
@immutable
class UserBehaviorSnapshot {
  const UserBehaviorSnapshot({
    required this.day,
    this.tasksCreated = 0,
    this.tasksCompleted = 0,
    this.tasksRescheduled = 0,
    this.tasksCompletedQ1 = 0,
    this.tasksCompletedQ2 = 0,
    this.tasksCompletedQ3 = 0,
    this.tasksCompletedQ4 = 0,
    this.focusSessionsCount = 0,
    this.totalFocusDuration = Duration.zero,
    this.nudgesShown = 0,
    this.nudgesActed = 0,
  });

  /// Fecha normalizada (sin hora) usada como clave del snapshot.
  final DateTime day;
  final int tasksCreated;
  final int tasksCompleted;
  final int tasksRescheduled;
  final int tasksCompletedQ1;
  final int tasksCompletedQ2;
  final int tasksCompletedQ3;
  final int tasksCompletedQ4;
  final int focusSessionsCount;
  final Duration totalFocusDuration;
  final int nudgesShown;
  final int nudgesActed;

  UserBehaviorSnapshot copyWith({
    DateTime? day,
    int? tasksCreated,
    int? tasksCompleted,
    int? tasksRescheduled,
    int? tasksCompletedQ1,
    int? tasksCompletedQ2,
    int? tasksCompletedQ3,
    int? tasksCompletedQ4,
    int? focusSessionsCount,
    Duration? totalFocusDuration,
    int? nudgesShown,
    int? nudgesActed,
  }) {
    return UserBehaviorSnapshot(
      day: day ?? this.day,
      tasksCreated: tasksCreated ?? this.tasksCreated,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksRescheduled: tasksRescheduled ?? this.tasksRescheduled,
      tasksCompletedQ1: tasksCompletedQ1 ?? this.tasksCompletedQ1,
      tasksCompletedQ2: tasksCompletedQ2 ?? this.tasksCompletedQ2,
      tasksCompletedQ3: tasksCompletedQ3 ?? this.tasksCompletedQ3,
      tasksCompletedQ4: tasksCompletedQ4 ?? this.tasksCompletedQ4,
      focusSessionsCount: focusSessionsCount ?? this.focusSessionsCount,
      totalFocusDuration: totalFocusDuration ?? this.totalFocusDuration,
      nudgesShown: nudgesShown ?? this.nudgesShown,
      nudgesActed: nudgesActed ?? this.nudgesActed,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day.toIso8601String(),
        'tasksCreated': tasksCreated,
        'tasksCompleted': tasksCompleted,
        'tasksRescheduled': tasksRescheduled,
        'tasksCompletedQ1': tasksCompletedQ1,
        'tasksCompletedQ2': tasksCompletedQ2,
        'tasksCompletedQ3': tasksCompletedQ3,
        'tasksCompletedQ4': tasksCompletedQ4,
        'focusSessionsCount': focusSessionsCount,
        'totalFocusDuration': totalFocusDuration.inSeconds,
        'nudgesShown': nudgesShown,
        'nudgesActed': nudgesActed,
      };

  factory UserBehaviorSnapshot.fromJson(Map<String, dynamic> json) {
    return UserBehaviorSnapshot(
      day: DateTime.parse(json['day'] as String),
      tasksCreated: json['tasksCreated'] as int? ?? 0,
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      tasksRescheduled: json['tasksRescheduled'] as int? ?? 0,
      tasksCompletedQ1: json['tasksCompletedQ1'] as int? ?? 0,
      tasksCompletedQ2: json['tasksCompletedQ2'] as int? ?? 0,
      tasksCompletedQ3: json['tasksCompletedQ3'] as int? ?? 0,
      tasksCompletedQ4: json['tasksCompletedQ4'] as int? ?? 0,
      focusSessionsCount: json['focusSessionsCount'] as int? ?? 0,
      totalFocusDuration: Duration(
        seconds: json['totalFocusDuration'] as int? ?? 0,
      ),
      nudgesShown: json['nudgesShown'] as int? ?? 0,
      nudgesActed: json['nudgesActed'] as int? ?? 0,
    );
  }
}
