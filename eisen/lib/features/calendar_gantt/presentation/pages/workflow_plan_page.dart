import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_chart.dart';

class WorkflowPlanPage extends ConsumerWidget {
  const WorkflowPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = ref.watch(lanesProvider);
    final projector = ref.watch(projectorProvider);

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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GanttChart(
                spans: spans,
                scale: TimeScale.weeks,
                viewStart: projector.viewStart,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
