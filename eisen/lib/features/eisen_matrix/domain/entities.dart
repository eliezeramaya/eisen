import 'dart:math' as math;

import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:equatable/equatable.dart';

/// Eisenhower matrix quadrant.
///
/// - [q1]: Urgent & Important (Do first)
/// - [q2]: Not urgent & Important (Schedule)
/// - [q3]: Urgent & Not important (Delegate)
/// - [q4]: Not urgent & Not important (Archive)
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
    this.kind = EntryKind.task,
    this.categoryId,
    this.subcategoryId,
    this.groupId,
    this.horizon,
    this.energy,
    this.inferredPriority,
    this.classificationConfidence,
    this.autoTags = const [],
    this.classificationMetadata,
    this.isArchived = false,
    this.archivedAt,
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

  // Smart Classification metadata
  final EntryKind kind;
  final String? categoryId;
  final String? subcategoryId;
  final String? groupId;
  final TimeHorizon? horizon;
  final EnergyLevel? energy;
  final PriorityLevel? inferredPriority;
  final ConfidenceLevel? classificationConfidence;
  final List<String> autoTags;
  final ClassificationMetadata? classificationMetadata;
  final bool isArchived;
  final DateTime? archivedAt;

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
    EntryKind? kind,
    String? categoryId,
    String? subcategoryId,
    String? groupId,
    TimeHorizon? horizon,
    EnergyLevel? energy,
    PriorityLevel? inferredPriority,
    ConfidenceLevel? classificationConfidence,
    List<String>? autoTags,
    ClassificationMetadata? classificationMetadata,
    bool? isArchived,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
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
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      groupId: groupId ?? this.groupId,
      horizon: horizon ?? this.horizon,
      energy: energy ?? this.energy,
      inferredPriority: inferredPriority ?? this.inferredPriority,
      classificationConfidence:
          classificationConfidence ?? this.classificationConfidence,
      autoTags: autoTags ?? this.autoTags,
      classificationMetadata:
          classificationMetadata ?? this.classificationMetadata,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
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
        kind,
        categoryId,
        subcategoryId,
        groupId,
        horizon,
        energy,
        inferredPriority,
        classificationConfidence,
        autoTags,
        classificationMetadata,
        isArchived,
        archivedAt,
      ];
}

/// Computes the visual weight for treemap layout.
///
/// Kept as the public API for existing layout, worker and test call sites.
double weight(Task t) {
  final basePriority = t.priority.clamp(1, 10).toDouble();
  final minutesFactor =
      math.pow(t.minutes.clamp(5, 240).toDouble(), 0.65).toDouble();
  final raw = basePriority *
      minutesFactor *
      _quadrantBoost(t.quadrant) *
      _confidenceFactor(t.classificationConfidence) *
      _horizonFactor(t.horizon) *
      _dueFactor(t.due) *
      _freshnessFactor(t);
  return raw.isFinite && !raw.isNaN ? math.max(0.0, raw) : 0.0;
}

double _quadrantBoost(Quadrant quadrant) {
  return switch (quadrant) {
    Quadrant.q1 => 1.30,
    Quadrant.q2 => 1.18,
    Quadrant.q3 => 0.92,
    Quadrant.q4 => 0.65,
  };
}

double _confidenceFactor(ConfidenceLevel? confidence) {
  return switch (confidence) {
    ConfidenceLevel.high => 1.00,
    ConfidenceLevel.medium => 0.92,
    ConfidenceLevel.low => 0.82,
    null => 0.90,
  };
}

double _horizonFactor(TimeHorizon? horizon) {
  return switch (horizon) {
    TimeHorizon.today => 1.18,
    TimeHorizon.thisWeek => 1.00,
    TimeHorizon.thisMonth => 0.85,
    TimeHorizon.someday => 0.65,
    null => 0.90,
  };
}

double _dueFactor(DateTime? due) {
  if (due == null) return 1.0;
  final daysToDue = due.difference(DateTime.now()).inHours / 24.0;
  return 1.0 + 0.18 * math.exp(-0.7 * math.max(0.0, daysToDue));
}

double _freshnessFactor(Task task) {
  final now = DateTime.now();
  final lastTouch = task.updatedAt ?? task.createdAt ?? now;
  final days = math.max(0.0, now.difference(lastTouch).inDays.toDouble());
  return 0.82 + 0.18 * math.exp(-0.15 * days);
}
