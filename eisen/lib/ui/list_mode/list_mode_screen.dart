import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/ui/list_mode/widgets/quadrant_bars_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modern list mode screen showing tasks as horizontal bars with visual weight
class ListModeScreen extends ConsumerWidget {
  const ListModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(matrixTasksProvider);

    // Group tasks by quadrant
    final quadrants = <Quadrant, List<Task>>{};
    for (final task in tasks) {
      if (task.completedAt == null) {
        quadrants.putIfAbsent(task.quadrant, () => []).add(task);
      }
    }

    // Sort tasks within each quadrant by weight (descending)
    for (final q in quadrants.keys) {
      quadrants[q]!.sort((a, b) {
        final weightA = _calculateWeight(a);
        final weightB = _calculateWeight(b);
        return weightB.compareTo(weightA);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE6E6E6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'List Mode',
          style: TextStyle(
            color: Color(0xFFE6E6E6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          // Filter or sort options
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF7C7C7C)),
            onPressed: () {
              // TODO: Show filter/sort options
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? _buildEmptyState()
          : _buildResponsiveLayout(context, quadrants, ref),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    Map<Quadrant, List<Task>> quadrants,
    WidgetRef ref,
  ) {
    // Calculate task counts for responsive spacing
    final q1Count = quadrants[Quadrant.q1]?.length ?? 0;
    final q2Count = quadrants[Quadrant.q2]?.length ?? 0;
    final q3Count = quadrants[Quadrant.q3]?.length ?? 0;
    final q4Count = quadrants[Quadrant.q4]?.length ?? 0;

    // Calculate responsive spacing (base + per task)
    // Minimum spacing: 16px, adds 3px per task up to a max
    double calculateSpacing(int count) {
      if (count == 0) return 8.0;
      return (16.0 + (count * 3.0)).clamp(16.0, 48.0);
    }

    final spacingQ1 = calculateSpacing(q1Count);
    final spacingQ2 = calculateSpacing(q2Count);
    final spacingQ3 = calculateSpacing(q3Count);
    final spacingQ4 = calculateSpacing(q4Count);

    // Central divider spacing (fixed to maintain visual separation)
    const centralDividerSpacing = 32.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Tareas organizadas por importancia',
              style: TextStyle(
                color: Color(0xFF7C7C7C),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Q1: Urgent & Important
          if (q1Count > 0)
            QuadrantBarsSection(
              quadrantName: 'Q1 · URGENTE E IMPORTANTE',
              description: 'Crisis y deadlines críticos',
              tasks: quadrants[Quadrant.q1]!,
              color: const Color(0xFFE84545),
              onTaskTap: (task) => _handleTaskTap(ref, task),
            ),
          if (q1Count > 0) SizedBox(height: spacingQ1),

          // Q2: Not Urgent but Important
          if (q2Count > 0)
            QuadrantBarsSection(
              quadrantName: 'Q2 · NO URGENTE E IMPORTANTE',
              description: 'Planificación y desarrollo',
              tasks: quadrants[Quadrant.q2]!,
              color: const Color(0xFFF4996E),
              onTaskTap: (task) => _handleTaskTap(ref, task),
            ),
          if (q2Count > 0) SizedBox(height: spacingQ2),

          // Central divider (visual separation between top and bottom)
          if ((q1Count > 0 || q2Count > 0) && (q3Count > 0 || q4Count > 0))
            Container(
              margin:
                  const EdgeInsets.symmetric(vertical: centralDividerSpacing),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF7C7C7C).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

          // Q3: Urgent but Not Important
          if (q3Count > 0)
            QuadrantBarsSection(
              quadrantName: 'Q3 · URGENTE Y NO IMPORTANTE',
              description: 'Interrupciones y distracciones',
              tasks: quadrants[Quadrant.q3]!,
              color: const Color(0xFF2563EB),
              onTaskTap: (task) => _handleTaskTap(ref, task),
            ),
          if (q3Count > 0) SizedBox(height: spacingQ3),

          // Q4: Neither Urgent nor Important
          if (q4Count > 0)
            QuadrantBarsSection(
              quadrantName: 'Q4 · NI URGENTE NI IMPORTANTE',
              description: 'Actividades de bajo valor',
              tasks: quadrants[Quadrant.q4]!,
              color: const Color(0xFFA3A3A3),
              onTaskTap: (task) => _handleTaskTap(ref, task),
            ),
          if (q4Count > 0) SizedBox(height: spacingQ4),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: const Color(0xFF7C7C7C).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay tareas',
            style: TextStyle(
              color: Color(0xFF7C7C7C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tareas desde la vista Matrix',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTaskTap(WidgetRef ref, Task task) {
    ref.read(matrixControllerProvider.notifier).select(task.id);
    // Could open a detail view or drawer here
  }

  double _calculateWeight(Task task) {
    final importance = _getImportanceScore(task.quadrant);
    final urgency = _getUrgencyScore(task.quadrant);
    final time = task.minutes.toDouble();
    return (importance * 0.7 + urgency * 0.3) * (time / 60.0);
  }

  double _getImportanceScore(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 10.0;
      case Quadrant.q2:
        return 8.0;
      case Quadrant.q3:
        return 5.0;
      case Quadrant.q4:
        return 3.0;
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
}
