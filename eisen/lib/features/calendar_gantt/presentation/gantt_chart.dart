import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_header.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_painter.dart';

/// Gantt chart scaffold with synchronized header/body scroll and Now line.
class GanttChart extends ConsumerStatefulWidget {
  final List<CalendarSpan> spans;
  final TimeScale scale;
  final DateTime viewStart;
  const GanttChart({
    super.key,
    required this.spans,
    required this.scale,
    required this.viewStart,
  });

  @override
  ConsumerState<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends ConsumerState<GanttChart> {
  final ScrollController _hHeader = ScrollController();
  final ScrollController _hBody = ScrollController();
  final ScrollController _vBody = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _hBody.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _hHeader.jumpTo(_hBody.offset);
      _syncing = false;
    });
    _hHeader.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _hBody.jumpTo(_hHeader.offset);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hHeader.dispose();
    _hBody.dispose();
    _vBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projector = ref.watch(projectorProvider);
    // View end: span max end + 7 days, or default window if empty
    DateTime viewEnd;
    if (widget.spans.isNotEmpty) {
      DateTime maxEnd = widget.viewStart.add(const Duration(days: 60));
      for (final s in widget.spans) {
        if (s.end.isAfter(maxEnd)) maxEnd = s.end;
      }
      viewEnd = maxEnd.add(const Duration(days: 7));
    } else {
      viewEnd = widget.viewStart.add(const Duration(days: 60));
    }
    final totalWidth = projector.widthBetween(widget.viewStart, viewEnd).clamp(600.0, 50000.0);

    // Lane count from spans (lane >= 0)
    int laneCount = 1;
    for (final s in widget.spans) {
      if (s.lane >= laneCount) laneCount = s.lane + 1;
    }
    final bodyHeight = (laneCount * UiTokens.laneHeight).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (horizontal scroll only)
        SizedBox(
          height: UiTokens.headerHeight,
          child: SingleChildScrollView(
            controller: _hHeader,
            scrollDirection: Axis.horizontal,
            child: GanttHeader(
              scale: widget.scale,
              projector: projector,
              viewStart: widget.viewStart,
              viewEnd: viewEnd,
              width: totalWidth,
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Body (both directions)
        Expanded(
          child: Container(
            color: UiTokens.bgDark,
            child: Scrollbar(
              controller: _vBody,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _vBody,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  controller: _hBody,
                  scrollDirection: Axis.horizontal,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(totalWidth, bodyHeight),
                      painter: GanttPainter(
                        projector: projector,
                        now: DateTime.now(),
                        spans: widget.spans,
                      ),
                      isComplex: true,
                      willChange: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
