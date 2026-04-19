import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Eisenhower matrix quadrant.
///
/// - [q1]: Urgent & Important (Do first)
/// - [q2]: Not urgent & Important (Schedule)
/// - [q3]: Urgent & Not important (Delegate)
/// - [q4]: Not urgent & Not important (Eliminate)
enum Quadrant { q1, q2, q3, q4 }

/// Task status for detailed workflow tracking
enum TaskStatus {
  pending, // Not started yet
  inProgress, // Currently being worked on
  blocked, // Waiting on external dependency
  completed, // Finished
  cancelled, // Cancelled or abandoned
}

/// Recurrence pattern for repeating tasks
enum RecurrencePattern {
  none, // One-time task
  daily, // Repeats every day
  weekly, // Repeats every week
  biweekly, // Repeats every 2 weeks
  monthly, // Repeats every month
  quarterly, // Repeats every 3 months
  yearly, // Repeats every year
}

/// Effort level for task estimation
enum EffortLevel {
  low, // Quick task, minimal effort
  medium, // Moderate effort required
  high, // Significant effort needed
  veryHigh, // Complex, time-intensive task
}

/// Subtask within a parent task
class Subtask extends Equatable {
  const Subtask({
    required this.id,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime? completedAt;

  Subtask copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
  }) {
    return Subtask(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, completed, completedAt];
}

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
///
/// Uses [Equatable] for structural equality to avoid unnecessary rebuilds
/// when task data hasn't meaningfully changed.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.priority,
    required this.minutes,
    this.due,
    this.tags = const [],
    this.categories = const [],
    this.notes,
    this.category,
    this.locationTag,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.replanCount = 0,
    this.snoozeCount = 0,
    this.normalizedPriority,
    this.normalizedMinutes,
    this.subtasks = const [],
    this.status = TaskStatus.pending,
    this.recurrence = RecurrencePattern.none,
    this.projectId,
    this.assignedTo,
    this.attachments = const [],
    this.effort = EffortLevel.medium,
    this.actualMinutes,
    this.startedAt,
    this.blockedReason,
    this.dependencies = const [],
  });
  final String id;
  final String title;
  final Quadrant quadrant;
  final int priority; // 1..10
  final int minutes; // estimated minutes
  final DateTime? due;
  final List<String> tags;

  /// Categorías definidas por el usuario para filtrado
  final List<String> categories;
  final String? notes;
  final String? category;
  final String? locationTag;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
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

  // Enhanced metadata
  final List<Subtask> subtasks;
  final TaskStatus status;
  final RecurrencePattern recurrence;
  final String? projectId;
  final String? assignedTo;
  final List<String> attachments; // URLs or file paths
  final EffortLevel effort;
  final int? actualMinutes; // Actual time spent (for tracking accuracy)
  final DateTime? startedAt; // When work began
  final String? blockedReason; // Why task is blocked
  final List<String> dependencies; // IDs of tasks this depends on

  Task copyWith({
    String? title,
    Quadrant? quadrant,
    int? priority,
    int? minutes,
    DateTime? due,
    List<String>? tags,
    List<String>? categories,
    String? notes,
    String? category,
    String? locationTag,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? replanCount,
    int? snoozeCount,
    double? normalizedPriority,
    double? normalizedMinutes,
    List<Subtask>? subtasks,
    TaskStatus? status,
    RecurrencePattern? recurrence,
    String? projectId,
    String? assignedTo,
    List<String>? attachments,
    EffortLevel? effort,
    int? actualMinutes,
    DateTime? startedAt,
    String? blockedReason,
    List<String>? dependencies,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      priority: priority ?? this.priority,
      minutes: minutes ?? this.minutes,
      due: due ?? this.due,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      locationTag: locationTag ?? this.locationTag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      replanCount: replanCount ?? this.replanCount,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      normalizedPriority: normalizedPriority ?? this.normalizedPriority,
      normalizedMinutes: normalizedMinutes ?? this.normalizedMinutes,
      subtasks: subtasks ?? this.subtasks,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      projectId: projectId ?? this.projectId,
      assignedTo: assignedTo ?? this.assignedTo,
      attachments: attachments ?? this.attachments,
      effort: effort ?? this.effort,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      startedAt: startedAt ?? this.startedAt,
      blockedReason: blockedReason ?? this.blockedReason,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  /// Derived convenience flags (not persisted)
  bool get isUrgent => quadrant.isUrgent;
  bool get isImportant => quadrant.isImportant;
  bool get isCompleted => completedAt != null;
  String get description => notes?.trim() ?? '';
  bool get hasLocationSignal => locationTag != null || hasCoordinates;
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Progress tracking
  double get subtaskProgress {
    if (subtasks.isEmpty) return 0.0;
    final completed = subtasks.where((s) => s.completed).length;
    return completed / subtasks.length;
  }

  bool get hasSubtasks => subtasks.isNotEmpty;
  int get completedSubtaskCount => subtasks.where((s) => s.completed).length;

  bool get isBlocked => status == TaskStatus.blocked;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isRecurring => recurrence != RecurrencePattern.none;

  bool get hasOverrun => actualMinutes != null && actualMinutes! > minutes;
  double? get timeAccuracy {
    if (actualMinutes == null || minutes == 0) return null;
    return (minutes - actualMinutes!).abs() / minutes;
  }

  /// Clamped projections used by layout/weighting.
  double get priorityClamped => priority.clamp(1, 10).toDouble();
  double get minutesClamped => minutes.clamp(5, 240).toDouble();

  /// Normalized [0..1] values. If user-provided normalized values exist,
  /// they are used; otherwise deterministic normalization is applied.
  double get priorityNorm =>
      (normalizedPriority ?? (priorityClamped - 1.0) / 9.0).clamp(0.0, 1.0);
  double get minutesNorm =>
      (normalizedMinutes ?? (minutesClamped - 5.0) / (240.0 - 5.0))
          .clamp(0.0, 1.0);

  /// Equatable props for structural equality (prevents unnecessary rebuilds).
  /// All fields that affect rendering/business logic are included.
  @override
  List<Object?> get props => [
        id,
        title,
        quadrant,
        priority,
        minutes,
        due,
        tags,
        categories,
        notes,
        category,
        locationTag,
        latitude,
        longitude,
        radiusMeters,
        createdAt,
        updatedAt,
        completedAt,
        replanCount,
        snoozeCount,
        normalizedPriority,
        normalizedMinutes,
        subtasks,
        status,
        recurrence,
        projectId,
        assignedTo,
        attachments,
        effort,
        actualMinutes,
        startedAt,
        blockedReason,
        dependencies,
      ];
}

/// Computes the visual weight for a task used by the treemap layout.
///
/// **Formula:**
/// ```
/// weight = priority^α × minutes^β × urgencyBoost × dueBoost × freshnessDecay
/// ```
///
/// **Parameters:**
/// - `α = 1.2`: Priority exponent (emphasizes high-priority tasks)
/// - `β = 0.8`: Minutes exponent (sub-linear to avoid extreme dominance)
/// - `urgencyBoost = 1.15` if urgent (Q1/Q3), else `1.0`
/// - `dueBoost = 1.0 + 0.25 × exp(-0.7 × daysToDue)`: Exponentially increases as due approaches
/// - `freshnessDecay = 0.75 + 0.25 × exp(-0.15 × daysSinceLastTouch)`: Slight decay for stale tasks
///
/// **Input Ranges (clamped internally):**
/// - `priority`: [1, 10] (user input clamped)
/// - `minutes`: [5, 240] (user input clamped)
/// - `daysToDue`: [0, ∞) (null due dates treated as ∞)
/// - `daysSinceLastTouch`: [0, ∞)
///
/// **Output Range:**
/// - Minimum: ~3.78 (priority=1, minutes=5, no boosts, max decay)
/// - Maximum: ~318.2 (priority=10, minutes=240, urgent, due today, fresh)
/// - Typical range: [10, 150] for most tasks
///
/// **Monotonicity Guarantees:**
/// 1. **Due date proximity:** For two otherwise-identical tasks A and B,
///    if A.due is earlier than B.due, then weight(A) >= weight(B).
/// 2. **Priority:** Higher priority always increases weight.
/// 3. **Minutes:** More minutes always increases weight (sub-linearly).
///
/// **Edge Cases:**
/// - No due date (`null`): `dueBoost = 1.0` (base weight)
/// - Due in past: `daysToDue` clamped to 0, `dueBoost = 1.25` (maximum urgency)
/// - Invalid values (NaN/infinite): Returns `0.0` safely
///
/// **Testing:** See `test/unit/domain/weight_monotonicity_test.dart` for
/// property-based tests verifying monotonicity and range bounds.
double weight(Task t) {
  const alpha = 1.2; // priority exponent
  const beta = 0.8; // minutes exponent
  final urgBoost = t.isUrgent ? 1.15 : 1.0;

  // Clipping to avoid outliers and instability
  final p = t.priority.clamp(1, 10).toDouble();
  final m = t.minutes.clamp(5, 240).toDouble();

  // 0..1: a menor distancia a due, mayor
  final now = DateTime.now();
  final daysToDue =
      t.due == null ? double.infinity : t.due!.difference(now).inHours / 24.0;
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
