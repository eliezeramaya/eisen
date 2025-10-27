import 'package:flutter/material.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';

/// Fixed header placeholder for the Gantt chart.
class GanttHeader extends StatelessWidget {
  final TimeScale scale;
  const GanttHeader({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: UiTokens.headerHeight,
      color: UiTokens.panelDark,
    );
  }
}
