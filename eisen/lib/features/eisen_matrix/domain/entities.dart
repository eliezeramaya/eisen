import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;

/// Eisenhower matrix quadrant.
///
/// - [q1]: Urgent & Important (Do first)
/// - [q2]: Not urgent & Important (Schedule)
/// - [q3]: Urgent & Not important (Delegate)
/// - [q4]: Not urgent & Not important (Eliminate)
enum Quadrant { q1, q2, q3, q4 }

/// Extension providing urgency and importance flags for quadrants.
extension QuadrantX on Quadrant {
  bool get isUrgent => this == Quadrant.q1 || this == Quadrant.q3;
  bool get isImportant => this == Quadrant.q1 || this == Quadrant.q2;
}

/// A task in the Eisenhower matrix.
///
/// Represents a single task with priority (1-10), estimated minutes,
/// and optional due date, tags, notes, and category.
///
/// Weight for layout is computed from priority × minutes × due-date urgency.
class Task {
  final String id;
  final String title;
  final Quadrant quadrant;
  final int priority; // 1..10
  final int minutes; // estimated minutes
  final DateTime? due;
  final List<String> tags;
  final String? notes;
  final String? category;
  // Volatile fields (not persisted): timestamps for freshness/analytics
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  // Volatile counters (not persisted): UX signals
  final int replanCount; // how many times re-scheduled/replanned recently
  final int snoozeCount; // how many times snoozed in recent window
  // Optional user-normalized values in [0..1] (not persisted)
  final double? normalizedPriority;
  final double? normalizedMinutes;

  const Task({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.priority,
    required this.minutes,
    this.due,
    this.tags = const [],
    this.notes,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.replanCount = 0,
    this.snoozeCount = 0,
    this.normalizedPriority,
    this.normalizedMinutes,
  });

  Task copyWith({
    String? title,
    Quadrant? quadrant,
    int? priority,
    int? minutes,
    DateTime? due,
    List<String>? tags,
    String? notes,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? replanCount,
    int? snoozeCount,
    double? normalizedPriority,
    double? normalizedMinutes,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      priority: priority ?? this.priority,
      minutes: minutes ?? this.minutes,
      due: due ?? this.due,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      replanCount: replanCount ?? this.replanCount,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      normalizedPriority: normalizedPriority ?? this.normalizedPriority,
      normalizedMinutes: normalizedMinutes ?? this.normalizedMinutes,
    );
  }

  /// Derived convenience flags (not persisted)
  bool get isUrgent => quadrant.isUrgent;
  bool get isImportant => quadrant.isImportant;

  /// Clamped projections used by layout/weighting.
  double get priorityClamped => priority.clamp(1, 10).toDouble();
  double get minutesClamped => minutes.clamp(5, 240).toDouble();

  /// Normalized [0..1] values. If user-provided normalized values exist,
  /// they are used; otherwise deterministic normalization is applied.
  double get priorityNorm => ((normalizedPriority ?? (priorityClamped - 1.0) / 9.0)).clamp(0.0, 1.0);
  double get minutesNorm => ((normalizedMinutes ?? (minutesClamped - 5.0) / (240.0 - 5.0))).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          quadrant == other.quadrant &&
          priority == other.priority &&
          minutes == other.minutes &&
          due == other.due &&
          listEquals(tags, other.tags) &&
          notes == other.notes &&
          category == other.category &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          completedAt == other.completedAt &&
          replanCount == other.replanCount &&
          snoozeCount == other.snoozeCount &&
          normalizedPriority == other.normalizedPriority &&
          normalizedMinutes == other.normalizedMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        quadrant,
        priority,
        minutes,
        due,
        Object.hashAll(tags),
        notes,
        category,
        createdAt,
        updatedAt,
        completedAt,
        replanCount,
        snoozeCount,
        normalizedPriority,
        normalizedMinutes,
      );
}

/// Computes the visual weight for a task used by the treemap layout.
///
/// Weight = priority × minutes × due-date urgency multiplier.
/// Tasks without due dates receive a base multiplier of 1.0.
/// Closer due dates receive higher multipliers exponentially.
///
/// Monotonicity guarantee w.r.t. due date proximity:
///   For two otherwise-identical tasks A and B, if A has an earlier due date
///   than B (i.e., fewer daysToDue), then weight(A) >= weight(B).
///   This is enforced via an increasing `dueBoost` factor when due approaches.
double weight(Task t) {
  const alpha = 1.2; // priority exponent
  const beta = 0.8; // minutes exponent
  final urgBoost = t.isUrgent ? 1.15 : 1.0;

  // Clipping to avoid outliers and instability
  final p = t.priority.clamp(1, 10).toDouble();
  final m = t.minutes.clamp(5, 240).toDouble();

  // 0..1: a menor distancia a due, mayor
  final now = DateTime.now();
  final daysToDue = t.due == null
      ? double.infinity
      : t.due!.difference(now).inHours / 24.0;
  final dl = daysToDue.isFinite ? math.max(0.0, daysToDue) : double.infinity;
  final deadlineSoon = dl.isFinite ? math.exp(-0.7 * dl) : 0.0; // [0..1]
  final dueBoost = 1.0 + 0.25 * deadlineSoon; // monotone w.r.t. due proximity

  // Decaimiento por “frescura” (última edición o creación)
  final lastTouch = t.updatedAt ?? t.createdAt ?? now;
  final lastDays = now.difference(lastTouch).inDays.toDouble();
  final freshness = math.exp(-0.15 * math.max(0.0, lastDays));

  final base = (math.pow(p, alpha) as double) * (math.pow(m, beta) as double);
  final raw = base * urgBoost * dueBoost * (0.75 + 0.25 * freshness);
  final safe = raw.isFinite && !raw.isNaN ? raw : 0.0;
  assert(safe >= 0, 'Negative weight');
  assert(safe.isFinite && !safe.isNaN, 'Invalid weight result');
  return safe;
}
