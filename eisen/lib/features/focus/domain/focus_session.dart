import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

/// Tipos de sesión de foco soportados.
enum FocusSessionType { deepWork, sprint, pomodoro }

/// Modelo base de una sesión de foco.
@immutable
class FocusSession {
  const FocusSession({
    required this.type,
    required this.plannedDuration,
    required this.startedAt,
    this.actualDuration,
    this.endedAt,
    this.linkedTask,
  });

  final FocusSessionType type;
  final Duration plannedDuration;
  final Duration? actualDuration;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Task? linkedTask;

  FocusSession copyWith({
    FocusSessionType? type,
    Duration? plannedDuration,
    Duration? actualDuration,
    DateTime? startedAt,
    DateTime? endedAt,
    Task? linkedTask,
  }) {
    return FocusSession(
      type: type ?? this.type,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      linkedTask: linkedTask ?? this.linkedTask,
    );
  }
}
