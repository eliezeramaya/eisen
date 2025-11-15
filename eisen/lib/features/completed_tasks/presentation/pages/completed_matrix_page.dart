import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/completed_tasks/application/completed_controller.dart';
import 'package:eisen/features/completed_tasks/presentation/widgets/filter_bar.dart';
import 'package:eisen/features/completed_tasks/presentation/widgets/zoom_control.dart';
import 'package:eisen/features/completed_tasks/presentation/widgets/completed_matrix_view.dart';
import 'package:eisen/features/completed_tasks/domain/filters.dart';
import 'package:eisen/features/completed_tasks/data/completed_tasks_repository.dart';

/// Completed tasks matrix page.
///
/// Displays all completed tasks in an Eisenhower matrix layout with:
/// - Time filters (All/Year/Month/Week/Day)
/// - Project filters
/// - Date navigation
/// - Zoom control
/// - InteractiveViewer for pan/zoom gestures
///
/// Route: `/completed-matrix`
class CompletedMatrixPage extends ConsumerStatefulWidget {
  const CompletedMatrixPage({super.key});

  /// Route name for navigation
  static const routeName = '/completed-matrix';

  @override
  ConsumerState<CompletedMatrixPage> createState() =>
      _CompletedMatrixPageState();
}

class _CompletedMatrixPageState extends ConsumerState<CompletedMatrixPage> {
  final _interactiveViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(completedMatrixProvider);
    final controller = ref.read(completedMatrixProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tareas Completadas'),
        backgroundColor: colorScheme.surfaceContainer,
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, state.stats),
            tooltip: 'Información',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          FilterBar(
            filter: state.filter,
            onTimeFilterChanged: (type) {
              controller.updateTimeFilter(type);
            },
            onDateChanged: (date) {
              controller.updateReferenceDate(date);
            },
            onProjectChanged: (project) {
              controller.updateProject(project);
            },
            onPreviousPeriod: () => controller.previousPeriod(),
            onNextPeriod: () => controller.nextPeriod(),
            onResetToToday: () => controller.resetToToday(),
          ),

          // Zoom control
          ZoomControl(
            value: state.zoomFactor,
            onChanged: (factor) {
              controller.setZoomFactor(factor);
            },
          ),

          // Warning for "All" filter
          if (state.isShowingAll && state.tasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.errorContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mostrando todas las tareas completadas. '
                      'Usa filtros para mejor rendimiento.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main content area
          Expanded(
            child: state.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando tareas...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : state.tasks.isEmpty
                    ? _EmptyState(filter: state.filter)
                    : InteractiveViewer(
                        key: _interactiveViewerKey,
                        minScale: 0.5,
                        maxScale: 2.0,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: CompletedMatrixView(
                          q1Tasks: state.q1Tasks,
                          q2Tasks: state.q2Tasks,
                          q3Tasks: state.q3Tasks,
                          q4Tasks: state.q4Tasks,
                          zoomFactor: state.zoomFactor,
                          onTaskTap: (id) {
                            controller.selectTask(
                              state.selectedTaskId == id ? null : id,
                            );
                          },
                          selectedTaskId: state.selectedTaskId,
                        ),
                      ),
          ),

          // Status bar at bottom
          if (state.stats != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _StatusBar(stats: state.stats!),
            ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, CompletedTasksStats? stats) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('Acerca de Tareas Completadas'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta pantalla muestra todas tus tareas completadas '
                'organizadas en la Matriz de Eisenhower.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Características:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _InfoItem(
                icon: Icons.filter_alt,
                text: 'Filtra por período: año, mes, semana o día',
              ),
              _InfoItem(
                icon: Icons.category,
                text: 'Filtra por proyecto o categoría',
              ),
              _InfoItem(
                icon: Icons.zoom_in,
                text: 'Ajusta el zoom para ver más o menos detalles',
              ),
              _InfoItem(
                icon: Icons.touch_app,
                text: 'Usa gestos para hacer pan y zoom',
              ),
              if (stats != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Estadísticas actuales:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('Total: ${stats.total} tareas'),
                Text('Tiempo total: ${stats.totalHours}h'),
                Text('Q1: ${stats.q1Count} | Q2: ${stats.q2Count}'),
                Text('Q3: ${stats.q3Count} | Q4: ${stats.q4Count}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Info item for dialog
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no completed tasks match filter
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
  });

  final CompletedTasksFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay tareas completadas',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Para el filtro actual: ${filter.description}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Could navigate back or reset filter
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a Matriz Principal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom status bar showing statistics
class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.stats,
  });

  final CompletedTasksStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.task_alt,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${stats.total} tareas',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.schedule,
          size: 20,
          color: colorScheme.tertiary,
        ),
        const SizedBox(width: 4),
        Text(
          '${stats.totalHours}h',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        // Quadrant distribution
        _QuadrantBadge(
          label: 'Q1',
          count: stats.q1Count,
          color: colorScheme.error,
        ),
        _QuadrantBadge(
          label: 'Q2',
          count: stats.q2Count,
          color: colorScheme.primary,
        ),
        _QuadrantBadge(
          label: 'Q3',
          count: stats.q3Count,
          color: colorScheme.tertiary,
        ),
        _QuadrantBadge(
          label: 'Q4',
          count: stats.q4Count,
          color: colorScheme.outline,
        ),
      ],
    );
  }
}

/// Small badge for quadrant count
class _QuadrantBadge extends StatelessWidget {
  const _QuadrantBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label:$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
