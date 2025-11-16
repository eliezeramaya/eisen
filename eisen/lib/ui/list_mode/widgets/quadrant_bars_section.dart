import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/ui/list_mode/widgets/task_bar_item.dart';
import 'package:flutter/material.dart';

/// Section displaying all tasks from a single quadrant as horizontal bars
class QuadrantBarsSection extends StatelessWidget {
  const QuadrantBarsSection({
    super.key,
    required this.quadrantName,
    required this.description,
    required this.tasks,
    required this.color,
    this.onTaskTap,
  });

  final String quadrantName;
  final String description;
  final List<Task> tasks;
  final Color color;
  final void Function(Task)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max weight for normalization
    final maxWeight = tasks
        .map(_calculateWeight)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quadrantName,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Task bars with staggered animation
        ...List.generate(tasks.length, (index) {
          final task = tasks[index];
          final weight = _calculateWeight(task);

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: TaskBarItem(
              title: task.title,
              color: color,
              weight: weight,
              maxWeight: maxWeight,
              subtitle: _formatSubtitle(task),
              onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
            ),
          );
        }),

        const SizedBox(height: 32),
      ],
    );
  }

  double _calculateWeight(Task task) {
    // Base weight calculation: importance (70%) + urgency (30%) × time
    final importance = _getImportanceScore(task.quadrant);
    final urgency = _getUrgencyScore(task.quadrant);
    final time = task.minutes.toDouble();

    return (importance * 0.7 + urgency * 0.3) * (time / 60.0);
  }

  double _getImportanceScore(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 10.0; // Urgent & Important
      case Quadrant.q2:
        return 8.0; // Not urgent but Important
      case Quadrant.q3:
        return 5.0; // Urgent but not Important
      case Quadrant.q4:
        return 3.0; // Neither urgent nor Important
    }
  }

  double _getUrgencyScore(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 10.0;
      case Quadrant.q2:
        return 4.0;
      case Quadrant.q3:
        return 8.0;
      case Quadrant.q4:
        return 2.0;
    }
  }

  String? _formatSubtitle(Task task) {
    if (task.due != null) {
      final now = DateTime.now();
      final diff = task.due!.difference(now).inDays;
      if (diff == 0) return 'Hoy';
      if (diff == 1) return 'Mañana';
      if (diff < 0) return '${diff.abs()}d atrás';
      if (diff < 7) return '${diff}d';
      return null;
    }
    return null;
  }
}
