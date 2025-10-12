import 'dart:math' as math;

enum Quadrant { q1, q2, q3, q4 }

class Task {
  final String id;
  final String title;
  final Quadrant quadrant;
  final int priority; // 1..10
  final int minutes; // estimated minutes
  final DateTime? due;
  final List<String> tags;
  final String? notes;

  const Task({
    required this.id,
    required this.title,
    required this.quadrant,
    required this.priority,
    required this.minutes,
    this.due,
    this.tags = const [],
    this.notes,
  });

  Task copyWith({
    String? title,
    Quadrant? quadrant,
    int? priority,
    int? minutes,
    DateTime? due,
    List<String>? tags,
    String? notes,
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
    );
  }
}

double weight(Task t) {
  const alpha = 1.2;
  const beta = 0.8;
  final urgBoost = (t.quadrant == Quadrant.q1 || t.quadrant == Quadrant.q3) ? 1.15 : 1.0;
  final prio = t.priority.clamp(1, 10).toDouble();
  final mins = (t.minutes <= 0 ? 1 : t.minutes).toDouble();
  return math.pow(prio, alpha) * math.pow(mins, beta) * urgBoost as double;
}

