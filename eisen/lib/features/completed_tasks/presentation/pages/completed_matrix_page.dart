import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/features/completed_tasks/application/completed_controller.dart';
import 'package:eisen/features/completed_tasks/presentation/widgets/completed_matrix_view.dart';
import 'package:eisen/features/completed_tasks/domain/filters.dart';
import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/features/completed_tasks/data/completed_tasks_repository.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';

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
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Row(
            children: [
              AppLogoHomeButton(),
              SizedBox(width: 8),
              Text('Tareas Completadas'),
            ],
          ),
        ),
        backgroundColor: colorScheme.surfaceContainer,
        actions: [
          // Filter button (opens bottom sheet)
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFiltersSheet(context, state, controller),
            tooltip: 'Filtros',
          ),
          // Zoom control (compact)
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _showZoomSheet(context, state, controller),
            tooltip: 'Zoom',
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, state.stats),
            tooltip: 'Información',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter description bar (compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  state.filter.timeType.icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.filter.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Zoom: ${(state.zoomFactor * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

  void _showFiltersSheet(
    BuildContext context,
    CompletedMatrixState state,
    CompletedMatrixController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time filter segments
            Text(
              'Período de tiempo',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TimeFilterType>(
              segments: TimeFilterType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.displayName),
                  icon: Icon(type.icon, size: 18),
                );
              }).toList(),
              selected: {state.filter.timeType},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  controller.updateTimeFilter(selection.first);
                }
              },
              showSelectedIcon: false,
            ),

            const SizedBox(height: 16),

            // Date navigation (only if not "all")
            if (state.filter.timeType != TimeFilterType.all) ...[
              Text(
                'Navegación',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: controller.previousPeriod,
                    tooltip: 'Anterior',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: state.filter.referenceDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('es'),
                        );
                        if (picked != null) {
                          controller.updateReferenceDate(picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_formatDateLabel(state.filter)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.today),
                    onPressed: controller.resetToToday,
                    tooltip: 'Hoy',
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: controller.nextPeriod,
                    tooltip: 'Siguiente',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Project filter
            Text(
              'Proyecto',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ProjectCategory>(
              initialValue: state.filter.project ?? ProjectCategory.all,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: ProjectCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value == ProjectCategory.all) {
                  controller.updateProject(null);
                } else {
                  controller.updateProject(value);
                }
              },
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.check),
              label: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showZoomSheet(
    BuildContext context,
    CompletedMatrixState state,
    CompletedMatrixController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.zoom_in, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Control de Zoom',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.zoom_out,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Slider(
                    value: state.zoomFactor,
                    min: 0.7,
                    max: 1.4,
                    divisions: 14,
                    label: '${(state.zoomFactor * 100).round()}%',
                    onChanged: controller.setZoomFactor,
                  ),
                ),
                Icon(
                  Icons.zoom_in,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(state.zoomFactor * 100).round()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(CompletedTasksFilter filter) {
    final date = filter.referenceDate;
    return switch (filter.timeType) {
      TimeFilterType.all => 'Todo',
      TimeFilterType.year => '${date.year}',
      TimeFilterType.month => '${_monthName(date.month)} ${date.year}',
      TimeFilterType.week => 'Semana del ${date.day}/${date.month}',
      TimeFilterType.day => '${date.day}/${date.month}/${date.year}',
    };
  }

  String _monthName(int month) => [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre'
      ][month - 1];

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
