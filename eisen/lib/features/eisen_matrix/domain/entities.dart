import 'dart:math' as math;

enum Quadrant { q1, q2, q3, q4 }

extension QuadrantX on Quadrant {
  bool get isUrgent => this == Quadrant.q1 || this == Quadrant.q2;
  bool get isImportant => this == Quadrant.q1 || this == Quadrant.q4;
}

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
    );
  }
}

/// Returns the base weight for a task used by the treemap layout.
///
/// Monotonicity guarantee w.r.t. due date proximity:
///   For two otherwise-identical tasks A and B, if A has an earlier due date
///   than B (i.e., fewer daysToDue), then weight(A) >= weight(B).
///   This is enforced via an increasing `dueBoost` factor when due approaches.
double weight(Task t) {
  const alpha = 1.2; // priority exponent
  const beta = 0.8; // minutes exponent
  final urgBoost = (t.quadrant == Quadrant.q1 || t.quadrant == Quadrant.q3) ? 1.15 : 1.0;

  // Clipping to avoid outliers and instability
  final p = t.priority.clamp(1, 10).toDouble();
  final m = t.minutes.clamp(5, 240).toDouble();

  // days to due (negative means overdue -> treat as 0 days left)
  double daysToDue;
  if (t.due == null) {
    daysToDue = double.infinity;
  } else {
    final now = DateTime.now();
    final diff = t.due!.difference(now).inMinutes / (60.0 * 24.0);
    daysToDue = diff.isFinite ? math.max(0.0, diff) : double.infinity;
  }
  final deadlineSoon = (daysToDue.isFinite) ? math.exp(-0.7 * daysToDue) : 0.0; // [0..1]
  final dueBoost = 1.0 + 0.25 * deadlineSoon; // [1..1.25]

  final lastTouch = t.updatedAt ?? t.createdAt;
  double lastTouchDays;
  if (lastTouch == null) {
    lastTouchDays = 7.0; // default decay
  } else {
    final diff = DateTime.now().difference(lastTouch).inMinutes / (60.0 * 24.0);
    lastTouchDays = diff.isFinite ? math.max(0.0, diff) : 7.0;
  }
  final freshness = math.exp(-0.15 * lastTouchDays); // [0..1]

  final base = (math.pow(p, alpha) as double) * (math.pow(m, beta) as double);
  final raw = base * urgBoost * dueBoost * (0.75 + 0.25 * freshness);
  return raw;
}
