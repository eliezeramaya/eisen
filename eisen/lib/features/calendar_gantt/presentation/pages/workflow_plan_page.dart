import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_lanes.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/demo/gantt_demo_data.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_chart.dart';
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

  @override
  Widget build(BuildContext context) {
    final projector = ref.watch(projectorProvider);
    final ui = ref.watch(uiPrefsProvider);

    // Decide data source
    final realSpans = ref.watch(lanesProvider);
    final showDemoToggle = kDebugMode || _needsDemoHint(realSpans);
    final spans = _useDemo ? assignLanes(demoSpans()) : realSpans;

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
                      const Spacer(),
                      if (showDemoToggle) ...[
                        Text(
                          (Localizations.localeOf(context).languageCode == 'es')
                              ? 'Usar demo'
                              : 'Use demo',
                          style: const TextStyle(color: Colors.white70),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GanttChart(
                      spans: spans,
                      scale: _scaleFrom(ui.ganttTimeScale),
                      viewStart: projector.viewStart,
                      milestones: milestones,
                      onSpanChanged: (oldS, up) {
                        // In a full implementation, map CalendarSpan -> Task and persist.
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
