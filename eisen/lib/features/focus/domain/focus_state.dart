import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';

/// Current status of a focus session
enum FocusStatus {
  idle, // Not started
  running, // Timer counting down
  paused, // Timer paused
  completed, // Session finished
}

/// Phase within a focus session
enum FocusPhase {
  focus, // Main work phase
  shortBreak, // 5-min break (Pomodoro)
  longBreak, // 15-min break (Pomodoro after 4 cycles)
}

/// State model for focus timer
class FocusState {
  final FocusStatus status;
  final FocusSessionType type;
  final FocusPhase phase;
  final Duration remaining;
  final Duration total;
  final Task? linkedTask;
  final int pomodoroCount; // Cycles completed (for Pomodoro type)

  const FocusState({
    required this.status,
    required this.type,
    required this.phase,
    required this.remaining,
    required this.total,
    this.linkedTask,
    this.pomodoroCount = 0,
  });

  /// Create initial idle state
  factory FocusState.idle() {
    return const FocusState(
      status: FocusStatus.idle,
      type: FocusSessionType.pomodoro,
      phase: FocusPhase.focus,
      remaining: Duration(minutes: 25),
      total: Duration(minutes: 25),
      linkedTask: null,
      pomodoroCount: 0,
    );
  }

  /// Progress from 0.0 to 1.0
  double get progress {
    if (total.inSeconds == 0) return 0.0;
    return 1.0 - (remaining.inSeconds / total.inSeconds);
  }

  /// Whether timer is actively running
  bool get isRunning => status == FocusStatus.running;

  /// Whether currently in break phase
  bool get isBreak => phase != FocusPhase.focus;

  /// Format remaining time as mm:ss
  String get formattedTime {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Copy with modifications
  FocusState copyWith({
    FocusStatus? status,
    FocusSessionType? type,
    FocusPhase? phase,
    Duration? remaining,
    Duration? total,
    Task? linkedTask,
    int? pomodoroCount,
  }) {
    return FocusState(
      status: status ?? this.status,
      type: type ?? this.type,
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
      linkedTask: linkedTask ?? this.linkedTask,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FocusState &&
        other.status == status &&
        other.type == type &&
        other.phase == phase &&
        other.remaining == remaining &&
        other.total == total &&
        other.linkedTask == linkedTask &&
        other.pomodoroCount == pomodoroCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      type,
      phase,
      remaining,
      total,
      linkedTask,
      pomodoroCount,
    );
  }
}
