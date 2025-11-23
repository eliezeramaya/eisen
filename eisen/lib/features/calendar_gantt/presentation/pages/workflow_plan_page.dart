import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/application/dependencies_controller.dart';
import 'package:eisen/features/calendar_gantt/demo/gantt_demo_data.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/domain/task_dependency.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_chart.dart';
import 'package:eisen/features/calendar_gantt/presentation/widgets/manage_dependencies_sheet.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowPlanPage extends ConsumerStatefulWidget {
  const WorkflowPlanPage({super.key});

  @override
  ConsumerState<WorkflowPlanPage> createState() => _WorkflowPlanPageState();
}

class _WorkflowPlanPageState extends ConsumerState<WorkflowPlanPage> {
  bool _useDemo = false;

  TimeScale _scaleFrom(String s) {
    switch (s) {
      case 'days':
        return TimeScale.days;
      case 'months':
        return TimeScale.months;
      case 'weeks':
      default:
        return TimeScale.weeks;
    }
  }

  String _summaryFor(List<CalendarSpan> spans, BuildContext context) {
    if (spans.isEmpty) return '';
    var minStart = spans.first.start;
    var maxEnd = spans.first.end;
    for (final s in spans) {
      if (s.start.isBefore(minStart)) minStart = s.start;
      if (s.end.isAfter(maxEnd)) maxEnd = s.end;
    }
    final days = maxEnd.difference(minStart).inDays.clamp(1, 10000);
    final months = days / 30.0;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final text = months.toStringAsFixed(1).replaceAll('.', isEs ? ',' : '.');
    return isEs ? '$text meses' : '$text months';
  }

  bool _needsDemoHint(List<CalendarSpan> spans) {
    // Show toggle if not many long spans
    final longCount =
        spans.where((s) => s.end.difference(s.start).inDays >= 7).length;
    return longCount < 4;
  }

  void _onSpanTap(Map<String, Task> tasksById, CalendarSpan span) {
    if (_useDemo) return;
    final task = tasksById[span.id];
    if (task == null) return;
    showManageDependenciesSheet(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final projector = ref.watch(projectorProvider);
    final ui = ref.watch(uiPrefsProvider);
    final tasks = ref.watch(matrixTasksProvider);
    final tasksById = {for (final t in tasks) t.id: t};

    // Decide data source - real tasks by default
    final realSpans = ref.watch(lanesProvider);
    final showDemoToggle = kDebugMode || _needsDemoHint(realSpans);
    final spans = _useDemo ? assignLanes(demoSpans()) : realSpans;
    final dependencies = _useDemo
        ? const <TaskDependency>[]
        : ref.watch(dependencyArrowsProvider);

    // Show helpful message if no real tasks
    final hasNoRealTasks = realSpans.isEmpty;

    // Demo milestone
    final milestones = _useDemo
        ? [
            (
              DateTime(2025, 3, 1),
              'Dev Start',
            ),
          ]
        : const <(DateTime, String)>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow plan'),
        backgroundColor: UiTokens.panelDark,
      ),
      backgroundColor: UiTokens.bgDark,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: UiTokens.panelDark,
            border: Border.all(color: UiTokens.divider, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Internal header: title + summary + optional demo toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Workflow plan',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(width: 12),
                      // Badge showing data source
                      if (!_useDemo && !hasNoRealTasks)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Text(
                            (Localizations.localeOf(context).languageCode ==
                                    'es')
                                ? '${spans.length} tareas reales'
                                : '${spans.length} real tasks',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (_useDemo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text(
                            (Localizations.localeOf(context).languageCode ==
                                    'es')
                                ? 'Datos de ejemplo'
                                : 'Demo data',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (showDemoToggle) ...[
                        Text(
                          (Localizations.localeOf(context).languageCode == 'es')
                              ? 'Ver demo'
                              : 'Show demo',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: _useDemo,
                          onChanged: (v) => setState(() => _useDemo = v),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        _summaryFor(spans, context),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                // Empty state message
                if (hasNoRealTasks && !_useDemo)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              (Localizations.localeOf(context).languageCode ==
                                      'es')
                                  ? 'No hay tareas con fechas de vencimiento'
                                  : 'No tasks with due dates yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (Localizations.localeOf(context).languageCode ==
                                      'es')
                                  ? 'Añade fechas de vencimiento a tus tareas en la matriz Eisenhower para verlas aquí'
                                  : 'Add due dates to your tasks in the Eisenhower matrix to see them here',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white54,
                                  ),
                            ),
                            if (showDemoToggle) ...[
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _useDemo = true),
                                icon: const Icon(Icons.visibility),
                                label: Text(
                                  (Localizations.localeOf(context)
                                              .languageCode ==
                                          'es')
                                      ? 'Ver ejemplo con datos de demo'
                                      : 'Show demo data example',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GanttChart(
                        spans: spans,
                        dependencies: dependencies,
                        scale: _scaleFrom(ui.ganttTimeScale),
                        viewStart: projector.viewStart,
                        milestones: milestones,
                        onSpanTap: _useDemo
                            ? null
                            : (span) => _onSpanTap(tasksById, span),
                        onSpanChanged: (oldSpan, updatedSpan) {
                          // Don't update demo spans
                          if (_useDemo) return;

                          // Map CalendarSpan changes back to Task updates
                          final controller =
                              ref.read(matrixControllerProvider.notifier);

                          // CalendarSpan.end is exclusive (end of day)
                          // Task.due should be the actual due date (inclusive)
                          final newDue =
                              updatedSpan.end.subtract(const Duration(days: 1));

                          // Calculate new duration if span was resized
                          final oldDays =
                              oldSpan.end.difference(oldSpan.start).inDays;
                          final newDays = updatedSpan.end
                              .difference(updatedSpan.start)
                              .inDays;
                          final wasResized = oldDays != newDays;

                          controller.updateTask(updatedSpan.id, (task) {
                            if (wasResized) {
                              // Update both due date and estimated minutes
                              // Assume 6 hours of effective work per day (360 minutes)
                              final newMinutes =
                                  (newDays * 360).clamp(15, 7200);
                              return task.copyWith(
                                due: newDue,
                                minutes: newMinutes,
                              );
                            } else {
                              // Only due date changed (drag-to-move)
                              return task.copyWith(due: newDue);
                            }
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
