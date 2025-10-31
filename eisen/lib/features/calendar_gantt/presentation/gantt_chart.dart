import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_header.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_interaction_layer.dart';
import 'package:eisen/features/calendar_gantt/presentation/gantt_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gantt chart scaffold with synchronized header/body scroll and Now line.
class GanttChart extends ConsumerStatefulWidget {
  const GanttChart({
    super.key,
    required this.spans,
    required this.scale,
    required this.viewStart,
    this.milestones = const <(DateTime, String)>[],
    this.onSpanChanged,
  });
  final List<CalendarSpan> spans;
  final TimeScale scale;
  final DateTime viewStart;
  final List<(DateTime, String)> milestones;
  final void Function(CalendarSpan oldSpan, CalendarSpan updated)?
      onSpanChanged;

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
    final ui = ref.watch(uiPrefsProvider);
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
    final totalWidth =
        projector.widthBetween(widget.viewStart, viewEnd).clamp(600.0, 50000.0);

    // Lane count from spans (lane >= 0)
    int laneCount = 1;
    for (final s in widget.spans) {
      if (s.lane >= laneCount) laneCount = s.lane + 1;
    }
    // Effective lane metrics (compact lanes -> 0.8x)
    final laneHeight =
        ui.ganttCompactLanes ? UiTokens.laneHeight * 0.8 : UiTokens.laneHeight;
    final laneGap =
        ui.ganttCompactLanes ? UiTokens.laneGap * 0.8 : UiTokens.laneGap;
    final bodyHeight = (laneCount * laneHeight).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (horizontal scroll only)
        SizedBox(
          height: UiTokens.headerHeight,
          child: SingleChildScrollView(
            controller: _hHeader,
            scrollDirection: Axis.horizontal,
            child: Stack(
              children: [
                // Header paint layer
                GanttHeader(
                  scale: widget.scale,
                  projector: projector,
                  viewStart: widget.viewStart,
                  viewEnd: viewEnd,
                  width: totalWidth,
                  workweekOnly: ui.ganttWorkweekOnly,
                ),
                // "Now" chip overlay aligned with the Now line
                Positioned(
                  left: projector.dx(DateTime.now()) - 18,
                  top: 6,
                  child: const _NowChip(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        // Body (both directions)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              return Container(
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
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              size: Size(totalWidth, bodyHeight),
                              painter: GanttPainter(
                                projector: projector,
                                now: DateTime.now(),
                                spans: widget.spans,
                                hScroll: _hBody,
                                viewportWidth: viewportWidth,
                                showBadges: ui.ganttShowBadges,
                                showTodayLine: ui.ganttShowTodayLine,
                                laneHeight: laneHeight,
                                laneGap: laneGap,
                                milestones: widget.milestones,
                              ),
                              isComplex: true,
                              willChange: false,
                            ),
                          ),
                          // Interaction layer (hover tooltip, cursor, ctrl+wheel & pinch zoom)
                          Positioned.fill(
                            child: GanttInteractionLayer(
                              spans: widget.spans,
                              projector: projector,
                              canvasSize: Size(totalWidth, bodyHeight),
                              hScroll: _hBody,
                              vScroll: _vBody,
                              laneHeight: laneHeight,
                              laneGap: laneGap,
                              onSpanChanged: widget.onSpanChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NowChip extends StatelessWidget {
  const _NowChip();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Small caret
        CustomPaint(
          size: const Size(8, 6),
          painter: _CaretPainter(color: UiTokens.now),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: UiTokens.now,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: UiTokens.now.withOpacity(.25), blurRadius: 8),
            ],
          ),
          child: const Text(
            'Now',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CaretPainter extends CustomPainter {
  _CaretPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.color != color;
}
