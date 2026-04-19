import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';

import 'completed_task_card.dart';

/// Matrix view for completed tasks organized in 4 quadrants.
///
/// Displays tasks in a 2x2 grid layout:
/// - Q1: Urgent & Important (top-left)
/// - Q2: Not Urgent & Important (top-right)
/// - Q3: Urgent & Not Important (bottom-left)
/// - Q4: Not Urgent & Not Important (bottom-right)
///
/// Each quadrant uses ListView.builder for performance with large lists.
class CompletedMatrixView extends StatelessWidget {
  const CompletedMatrixView({
    super.key,
    required this.q1Tasks,
    required this.q2Tasks,
    required this.q3Tasks,
    required this.q4Tasks,
    required this.zoomFactor,
    this.onTaskTap,
    this.selectedTaskId,
  });

  final List<Task> q1Tasks;
  final List<Task> q2Tasks;
  final List<Task> q3Tasks;
  final List<Task> q4Tasks;
  final double zoomFactor;
  final ValueChanged<String>? onTaskTap;
  final String? selectedTaskId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Responsive: Use single column on narrow screens
        if (width < 600) {
          return _SingleColumnLayout(
            q1Tasks: q1Tasks,
            q2Tasks: q2Tasks,
            q3Tasks: q3Tasks,
            q4Tasks: q4Tasks,
            zoomFactor: zoomFactor,
            onTaskTap: onTaskTap,
            selectedTaskId: selectedTaskId,
          );
        }

        // 2x2 grid for wider screens
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Q1: Top-left
                  Expanded(
                    child: _QuadrantPanel(
                      quadrant: Quadrant.q1,
                      tasks: q1Tasks,
                      zoomFactor: zoomFactor,
                      onTaskTap: onTaskTap,
                      selectedTaskId: selectedTaskId,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Q2: Top-right
                  Expanded(
                    child: _QuadrantPanel(
                      quadrant: Quadrant.q2,
                      tasks: q2Tasks,
                      zoomFactor: zoomFactor,
                      onTaskTap: onTaskTap,
                      selectedTaskId: selectedTaskId,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  // Q3: Bottom-left
                  Expanded(
                    child: _QuadrantPanel(
                      quadrant: Quadrant.q3,
                      tasks: q3Tasks,
                      zoomFactor: zoomFactor,
                      onTaskTap: onTaskTap,
                      selectedTaskId: selectedTaskId,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Q4: Bottom-right
                  Expanded(
                    child: _QuadrantPanel(
                      quadrant: Quadrant.q4,
                      tasks: q4Tasks,
                      zoomFactor: zoomFactor,
                      onTaskTap: onTaskTap,
                      selectedTaskId: selectedTaskId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Single quadrant panel with header and task list.
class _QuadrantPanel extends StatelessWidget {
  const _QuadrantPanel({
    required this.quadrant,
    required this.tasks,
    required this.zoomFactor,
    this.onTaskTap,
    this.selectedTaskId,
  });

  final Quadrant quadrant;
  final List<Task> tasks;
  final double zoomFactor;
  final ValueChanged<String>? onTaskTap;
  final String? selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _getQuadrantBgColor(quadrant, colorScheme),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 12 * zoomFactor,
              horizontal: 16 * zoomFactor,
            ),
            decoration: BoxDecoration(
              color: _getQuadrantColor(quadrant, colorScheme)
                  .withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: _getQuadrantColor(quadrant, colorScheme),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getQuadrantIcon(quadrant),
                  size: 20 * zoomFactor,
                  color: _getQuadrantColor(quadrant, colorScheme),
                ),
                SizedBox(width: 8 * zoomFactor),
                Expanded(
                  child: Text(
                    _getQuadrantTitle(quadrant),
                    style: TextStyle(
                      fontSize: 16 * zoomFactor,
                      fontWeight: FontWeight.bold,
                      color: _getQuadrantColor(quadrant, colorScheme),
                    ),
                  ),
                ),
                // Count badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * zoomFactor,
                    vertical: 4 * zoomFactor,
                  ),
                  decoration: BoxDecoration(
                    color: _getQuadrantColor(quadrant, colorScheme),
                    borderRadius: BorderRadius.circular(12 * zoomFactor),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 12 * zoomFactor,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task list or empty state
          Expanded(
            child: tasks.isEmpty
                ? _EmptyQuadrant(quadrant: quadrant, zoomFactor: zoomFactor)
                : ListView.builder(
                    padding: EdgeInsets.all(8 * zoomFactor),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8 * zoomFactor),
                        child: CompletedTaskCard(
                          task: task,
                          zoomFactor: zoomFactor,
                          onTap: onTaskTap != null
                              ? () => onTaskTap!(task.id)
                              : null,
                          isSelected: selectedTaskId == task.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getQuadrantColor(Quadrant q, ColorScheme cs) => switch (q) {
        Quadrant.q1 => cs.error,
        Quadrant.q2 => cs.primary,
        Quadrant.q3 => cs.tertiary,
        Quadrant.q4 => cs.outline,
      };

  Color _getQuadrantBgColor(Quadrant q, ColorScheme cs) => switch (q) {
        Quadrant.q1 => cs.errorContainer.withValues(alpha: 0.05),
        Quadrant.q2 => cs.primaryContainer.withValues(alpha: 0.05),
        Quadrant.q3 => cs.tertiaryContainer.withValues(alpha: 0.05),
        Quadrant.q4 => cs.surfaceContainerLowest,
      };

  IconData _getQuadrantIcon(Quadrant q) => switch (q) {
        Quadrant.q1 => Icons.priority_high,
        Quadrant.q2 => Icons.schedule,
        Quadrant.q3 => Icons.forward_to_inbox,
        Quadrant.q4 => Icons.delete_outline,
      };

  String _getQuadrantTitle(Quadrant q) => switch (q) {
        Quadrant.q1 => 'Q1: Hacer Primero',
        Quadrant.q2 => 'Q2: Programar',
        Quadrant.q3 => 'Q3: Delegar',
        Quadrant.q4 => 'Q4: Eliminar',
      };
}

/// Empty state for quadrant with no completed tasks
class _EmptyQuadrant extends StatelessWidget {
  const _EmptyQuadrant({required this.quadrant, required this.zoomFactor});

  final Quadrant quadrant;
  final double zoomFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * zoomFactor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48 * zoomFactor,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            SizedBox(height: 12 * zoomFactor),
            Text(
              'Sin tareas completadas',
              style: TextStyle(
                fontSize: 14 * zoomFactor,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4 * zoomFactor),
            Text(
              'en este cuadrante para el filtro actual',
              style: TextStyle(
                fontSize: 12 * zoomFactor,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single column layout for mobile/narrow screens
class _SingleColumnLayout extends StatelessWidget {
  const _SingleColumnLayout({
    required this.q1Tasks,
    required this.q2Tasks,
    required this.q3Tasks,
    required this.q4Tasks,
    required this.zoomFactor,
    this.onTaskTap,
    this.selectedTaskId,
  });

  final List<Task> q1Tasks;
  final List<Task> q2Tasks;
  final List<Task> q3Tasks;
  final List<Task> q4Tasks;
  final double zoomFactor;
  final ValueChanged<String>? onTaskTap;
  final String? selectedTaskId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _QuadrantPanel(
          quadrant: Quadrant.q1,
          tasks: q1Tasks,
          zoomFactor: zoomFactor,
          onTaskTap: onTaskTap,
          selectedTaskId: selectedTaskId,
        ),
        const Divider(height: 1),
        _QuadrantPanel(
          quadrant: Quadrant.q2,
          tasks: q2Tasks,
          zoomFactor: zoomFactor,
          onTaskTap: onTaskTap,
          selectedTaskId: selectedTaskId,
        ),
        const Divider(height: 1),
        _QuadrantPanel(
          quadrant: Quadrant.q3,
          tasks: q3Tasks,
          zoomFactor: zoomFactor,
          onTaskTap: onTaskTap,
          selectedTaskId: selectedTaskId,
        ),
        const Divider(height: 1),
        _QuadrantPanel(
          quadrant: Quadrant.q4,
          tasks: q4Tasks,
          zoomFactor: zoomFactor,
          onTaskTap: onTaskTap,
          selectedTaskId: selectedTaskId,
        ),
      ],
    );
  }
}
