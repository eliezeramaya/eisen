import 'dart:math' as math;

import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_projection.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_providers.dart';
import 'package:eisen/features/calendar_gantt/application/gantt_snap.dart';
import 'package:eisen/features/calendar_gantt/domain/calendar_span.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight interaction layer for the Gantt body.
/// - Hover hit-test to show a small tooltip with span title and dates (desktop)
/// - Cursor changes to click over bars
/// - Ctrl + mouse wheel zoom (desktop)
/// - Pinch-to-zoom (touch)
class GanttInteractionLayer extends ConsumerStatefulWidget {
  const GanttInteractionLayer({
    super.key,
    required this.spans,
    required this.projector,
    required this.canvasSize,
    required this.hScroll,
    required this.vScroll,
    required this.laneHeight,
    required this.laneGap,
    this.onSpanChanged,
    this.onSpanTap,
    this.spanRects,
  });
  final List<CalendarSpan> spans;
  final TimelineProjector projector;
  final Size canvasSize;
  final ScrollController hScroll;
  final ScrollController vScroll;
  final double laneHeight;
  final double laneGap;
  final void Function(CalendarSpan oldSpan, CalendarSpan updated)?
      onSpanChanged;
  final void Function(CalendarSpan span)? onSpanTap;
  final List<(CalendarSpan, Rect)>? spanRects;

  @override
  ConsumerState<GanttInteractionLayer> createState() =>
      _GanttInteractionLayerState();
}

class _GanttInteractionLayerState extends ConsumerState<GanttInteractionLayer> {
  // Hover state
  CalendarSpan? _hoverSpan;
  Rect? _hoverRect;
  Offset? _lastPos; // local (within canvas)
  _HandleHover _handleHover = _HandleHover.none;

  // Pinch zoom state
  double? _pinchBasePx;

  // Drag/resize state
  _DragMode _dragMode = _DragMode.none;
  CalendarSpan? _dragOrigSpan;
  Rect? _dragOrigRect;
  Offset? _dragStart;
  CalendarSpan? _dragPreviewSpan;
  Rect? _dragPreviewRect;

  // A11y & keyboard focus
  final Map<String, FocusNode> _focusNodes = {};
  String? _focusedId;
  String? _selectedId;

  @override
  void dispose() {
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }

  List<(CalendarSpan, Rect)> _computeRects() {
    final barHeight = widget.laneHeight - widget.laneGap;
    final yPad = widget.laneGap / 2;
    final rects = <(CalendarSpan, Rect)>[];
    for (final s in widget.spans) {
      if (s.lane < 0) continue;
      final left = widget.projector.dx(s.start);
      final right = widget.projector.dx(s.end);
      final w = (right - left).toDouble();
      if (w < 0.5) continue;
      final y = s.lane * widget.laneHeight + yPad;
      final r = Rect.fromLTWH(left, y.toDouble(), w, barHeight);
      rects.add((s, r));
    }
    return rects;
  }

  TimeScale _snapScale(WidgetRef ref) =>
      timeScaleFromPrefs(ref.read(uiPrefsProvider).ganttTimeScale);

  // Snapping handled via gantt_snap.dart utilities
  CalendarSpan _withDates(CalendarSpan s, DateTime start, DateTime end) {
    return s.copyWith(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    // Compute rects once per build; cheap
    final rects = widget.spanRects ?? _computeRects();
    // Focus nodes lifecycle
    for (final entry in rects) {
      _focusNodes.putIfAbsent(
          entry.$1.id, () => FocusNode(debugLabel: 'GanttBar:${entry.$1.id}'));
    }
    final ids = rects.map((e) => e.$1.id).toSet();
    _focusNodes.keys.where((k) => !ids.contains(k)).toList().forEach((k) {
      _focusNodes[k]?.dispose();
      _focusNodes.remove(k);
    });

    // Tooltip
    Widget? tooltip;
    final pos = _lastPos;
    final span = _hoverSpan;
    final rect = _hoverRect;
    if (pos != null &&
        span != null &&
        rect != null &&
        _dragMode == _DragMode.none) {
      final tooltipChild =
          _TooltipCard(title: span.title, start: span.start, end: span.end);
      final maxX = widget.canvasSize.width - 8;
      final maxY = widget.canvasSize.height - 8;
      final dx = math.min(pos.dx + 12, maxX - 220);
      final dy = math.min(pos.dy + 12, maxY - 80);
      tooltip = Positioned(left: dx, top: dy, child: tooltipChild);
    }

    // Handles and drag overlay
    Widget? handles;
    if (_hoverRect != null &&
        _hoverSpan != null &&
        _dragMode == _DragMode.none) {
      final r = _hoverRect!;
      handles = Positioned(
          left: r.left - 8,
          top: r.center.dy - 8,
          child: _HandleDot(active: _handleHover == _HandleHover.left));
    }
    Widget? handlesRight;
    if (_hoverRect != null &&
        _hoverSpan != null &&
        _dragMode == _DragMode.none) {
      final r = _hoverRect!;
      handlesRight = Positioned(
          left: r.right - 8,
          top: r.center.dy - 8,
          child: _HandleDot(active: _handleHover == _HandleHover.right));
    }
    Widget? dragOverlay;
    if (_dragPreviewRect != null) {
      final r = _dragPreviewRect!;
      dragOverlay = Positioned(
        left: r.left,
        top: r.top,
        child: Container(
          width: r.width,
          height: r.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
        ),
      );
    }

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const _GoRightIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _GoLeftIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const _GoUpIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const _GoDownIntent(),
          LogicalKeySet(LogicalKeyboardKey.enter): const _SelectIntent(),
          LogicalKeySet(LogicalKeyboardKey.escape): const _ClearIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _GoRightIntent: CallbackAction<_GoRightIntent>(
                onInvoke: (_) => _moveHorizontal(1, rects)),
            _GoLeftIntent: CallbackAction<_GoLeftIntent>(
                onInvoke: (_) => _moveHorizontal(-1, rects)),
            _GoUpIntent: CallbackAction<_GoUpIntent>(
                onInvoke: (_) => _moveVertical(-1, rects)),
            _GoDownIntent: CallbackAction<_GoDownIntent>(
                onInvoke: (_) => _moveVertical(1, rects)),
            _SelectIntent: CallbackAction<_SelectIntent>(
                onInvoke: (_) => _selectFocused(rects)),
            _ClearIntent: CallbackAction<_ClearIntent>(
                onInvoke: (_) => _clearSelection()),
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _onPointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (d) {
                // Track zoom baseline
                _pinchBasePx = ref.read(projectorProvider).pxPerDay;
                // Start drag with single pointer
                if (d.pointerCount == 1) {
                  final local = d.localFocalPoint;
                  for (final entry in rects) {
                    if (entry.$2.contains(local)) {
                      _beginDrag(local, entry.$1, entry.$2);
                      break;
                    }
                  }
                }
              },
              onScaleUpdate: (d) {
                // Pinch zoom when two+ pointers
                if (d.pointerCount >= 2) {
                  final base = _pinchBasePx;
                  if (base != null) {
                    final pc = ref.read(projectorProvider.notifier);
                    pc.setPxPerDay((base * d.scale).clamp(1.0, 1000.0));
                  }
                } else if (_dragMode != _DragMode.none) {
                  // Single-finger drag/resize uses focal point
                  _updateDrag(d.localFocalPoint);
                }
              },
              onScaleEnd: (_) {
                if (_dragMode != _DragMode.none) {
                  _endDrag();
                }
              },
              onTapUp: (details) {
                if (widget.onSpanTap == null || _dragMode != _DragMode.none) {
                  return;
                }
                final local = details.localPosition;
                for (final entry in rects) {
                  if (entry.$2.contains(local)) {
                    widget.onSpanTap?.call(entry.$1);
                    setState(() => _selectedId = entry.$1.id);
                    break;
                  }
                }
              },
              child: MouseRegion(
                cursor: _dragMode != _DragMode.none
                    ? SystemMouseCursors.grabbing
                    : _handleHover == _HandleHover.left ||
                            _handleHover == _HandleHover.right
                        ? SystemMouseCursors.resizeLeftRight
                        : (_hoverSpan != null
                            ? SystemMouseCursors.move
                            : SystemMouseCursors.basic),
                onHover: (event) {
                  final local = event.localPosition;
                  CalendarSpan? foundSpan;
                  Rect? foundRect;
                  for (final entry in rects) {
                    if (entry.$2.contains(local)) {
                      foundSpan = entry.$1;
                      foundRect = entry.$2;
                      break;
                    }
                  }
                  var handle = _HandleHover.none;
                  if (foundRect != null) {
                    const pad = 8.0;
                    if ((local.dx - foundRect.left).abs() <= pad) {
                      handle = _HandleHover.left;
                    }
                    if ((local.dx - foundRect.right).abs() <= pad) {
                      handle = _HandleHover.right;
                    }
                  }
                  setState(() {
                    _lastPos = local;
                    _hoverSpan = foundSpan;
                    _hoverRect = foundRect;
                    _handleHover = handle;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hoverSpan = null;
                    _hoverRect = null;
                    _lastPos = null;
                    _handleHover = _HandleHover.none;
                  });
                },
                child: SizedBox(
                  width: widget.canvasSize.width,
                  height: widget.canvasSize.height,
                  child: Stack(children: [
                    // Accessibility overlay: Semantics + Focus targets
                    ...rects.map((e) {
                      final span = e.$1;
                      final r = e.$2;
                      final node = _focusNodes[span.id]!;
                      final isSelected = _selectedId == span.id;
                      return Positioned(
                        left: r.left,
                        top: r.top,
                        width: r.width,
                        height: r.height,
                        child: Semantics(
                          label: span.title,
                          value: _semanticsValue(span),
                          hint:
                              'Use arrow keys to navigate. Press Enter to select. Press Escape to clear.',
                          button: true,
                          onTap: () {
                            setState(() {
                              _selectedId = span.id;
                            });
                            node.requestFocus();
                          },
                          child: FocusableActionDetector(
                            focusNode: node,
                            onShowFocusHighlight: (_) => setState(() {}),
                            onShowHoverHighlight: (_) {},
                            onFocusChange: (has) {
                              if (has) setState(() => _focusedId = span.id);
                            },
                            child: IgnorePointer(
                              child: Container(
                                decoration: (isSelected || node.hasFocus)
                                    ? BoxDecoration(
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            width: 1.5),
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (dragOverlay != null) dragOverlay,
                    if (handles != null) handles,
                    if (handlesRight != null) handlesRight,
                    if (tooltip != null) tooltip,
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsValue(CalendarSpan span) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    final s = span.start;
    final e = span.end;
    final days = e.difference(s).inDays.clamp(1, 999);
    final startStr = '${s.year}-${two(s.month)}-${two(s.day)}';
    final endStr = '${e.year}-${two(e.month)}-${two(e.day)}';
    return '$startStr to $endStr, $days days';
  }

  void _clearSelection() {
    setState(() => _selectedId = null);
  }

  void _selectFocused(List<(CalendarSpan, Rect)> rects) {
    final id = _focusedId;
    if (id == null) return;
    setState(() => _selectedId = id);
  }

  void _moveHorizontal(int dir, List<(CalendarSpan, Rect)> rects) {
    if (rects.isEmpty) return;
    // Order by lane then start
    final ordered = [...rects]..sort((a, b) {
        final c = a.$1.lane.compareTo(b.$1.lane);
        if (c != 0) return c;
        return a.$1.start.compareTo(b.$1.start);
      });
    final currentId = _focusedId ?? ordered.first.$1.id;
    final idx = ordered.indexWhere((e) => e.$1.id == currentId);
    final next = (idx + dir).clamp(0, ordered.length - 1);
    final target = ordered[next].$1.id;
    _focusNodes[target]?.requestFocus();
    setState(() => _focusedId = target);
  }

  void _moveVertical(int laneDelta, List<(CalendarSpan, Rect)> rects) {
    if (rects.isEmpty) return;
    // Build by-lane map
    final byLane = <int, List<(CalendarSpan, Rect)>>{};
    for (final e in rects) {
      byLane.putIfAbsent(e.$1.lane, () => []).add(e);
    }
    final current = rects.firstWhere(
      (e) => e.$1.id == (_focusedId ?? rects.first.$1.id),
      orElse: () => rects.first,
    );
    final currentLane = current.$1.lane;
    final targetLane = currentLane + laneDelta;
    final laneList = byLane[targetLane];
    if (laneList == null || laneList.isEmpty) return;
    // Pick bar whose center x is closest to current center x
    final cx = current.$2.center.dx;
    (CalendarSpan, Rect)? best;
    double bestDx = double.infinity;
    for (final e in laneList) {
      final d = (e.$2.center.dx - cx).abs();
      if (d < bestDx) {
        bestDx = d;
        best = e;
      }
    }
    if (best != null) {
      final targetId = best.$1.id;
      _focusNodes[targetId]?.requestFocus();
      setState(() => _focusedId = targetId);
    }
  }

  // Zoom via mouse wheel + Ctrl
  void _onPointerSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final keys = RawKeyboard.instance.keysPressed;
    final ctrl = keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
    if (!ctrl) return;
    final dy = e.scrollDelta.dy; // up = -ve, down = +ve
    final pc = ref.read(projectorProvider.notifier);
    final current = ref.read(projectorProvider).pxPerDay;
    // Exponential-ish zoom step for smoothness
    final factor = math.pow(2.0, (-dy) / 600.0).toDouble();
    pc.setPxPerDay((current * factor).clamp(1.0, 1000.0));
  }

  void _beginDrag(Offset local, CalendarSpan span, Rect rect) {
    _dragOrigSpan = span;
    _dragOrigRect = rect;
    _dragStart = local;
    switch (_handleHover) {
      case _HandleHover.left:
        _dragMode = _DragMode.resizeLeft;
        break;
      case _HandleHover.right:
        _dragMode = _DragMode.resizeRight;
        break;
      case _HandleHover.none:
        _dragMode = _DragMode.move;
        break;
    }
    setState(() {
      _dragPreviewSpan = span;
      _dragPreviewRect = rect;
    });
  }

  void _updateDrag(Offset local) {
    if (_dragMode == _DragMode.none ||
        _dragOrigSpan == null ||
        _dragOrigRect == null ||
        _dragStart == null) {
      return;
    }
    final scale = _snapScale(ref);
    final proj = widget.projector;

    CalendarSpan updated = _dragOrigSpan!;
    switch (_dragMode) {
      case _DragMode.move:
        final dx = local.dx - _dragStart!.dx;
        final newLeft = _dragOrigRect!.left + dx;
        final startT = proj.timeAt(newLeft);
        final snappedStart = snapFloor(startT, scale);
        final durDays = math.max(
            1, _dragOrigSpan!.end.difference(_dragOrigSpan!.start).inDays);
        final newEnd = snappedStart.add(Duration(days: durDays));
        updated = _withDates(_dragOrigSpan!, snappedStart, newEnd);
        break;
      case _DragMode.resizeLeft:
        final t = proj.timeAt(local.dx);
        final snapped = snapFloor(t, scale);
        // Ensure start < end by at least 1 day
        var start = snapped;
        final end = _dragOrigSpan!.end;
        if (!start.isBefore(end)) {
          start = end.subtract(const Duration(days: 1));
        }
        updated = _withDates(_dragOrigSpan!, start, end);
        break;
      case _DragMode.resizeRight:
        final t = proj.timeAt(local.dx);
        // Snap to boundary, then advance by step size so right edge lands on next boundary
        final base = snapFloor(t, scale);
        final step = stepDaysForScale(scale);
        var end = base.add(Duration(days: step));
        final start = _dragOrigSpan!.start;
        if (!start.isBefore(end)) {
          end = start.add(const Duration(days: 1));
        }
        updated = _withDates(_dragOrigSpan!, start, end);
        break;
      case _DragMode.none:
        break;
    }

    final left = proj.dx(updated.start);
    final right = proj.dx(updated.end);
    final r = Rect.fromLTWH(
        left, _dragOrigRect!.top, right - left, _dragOrigRect!.height);
    setState(() {
      _dragPreviewSpan = updated;
      _dragPreviewRect = r;
    });
  }

  void _endDrag() {
    if (_dragMode == _DragMode.none) return;
    final updated = _dragPreviewSpan;
    final orig = _dragOrigSpan;
    setState(() {
      _dragMode = _DragMode.none;
      _dragOrigSpan = null;
      _dragOrigRect = null;
      _dragStart = null;
      _dragPreviewRect = null;
    });
    if (updated != null && orig != null && widget.onSpanChanged != null) {
      widget.onSpanChanged!(orig, updated);
    }
  }
}

enum _DragMode { none, move, resizeLeft, resizeRight }

enum _HandleHover { none, left, right }

// Keyboard intents
class _GoLeftIntent extends Intent {
  const _GoLeftIntent();
}

class _GoRightIntent extends Intent {
  const _GoRightIntent();
}

class _GoUpIntent extends Intent {
  const _GoUpIntent();
}

class _GoDownIntent extends Intent {
  const _GoDownIntent();
}

class _SelectIntent extends Intent {
  const _SelectIntent();
}

class _ClearIntent extends Intent {
  const _ClearIntent();
}

class _HandleDot extends StatelessWidget {
  const _HandleDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color fill =
        active ? cs.primary : Colors.white.withValues(alpha: 0.08);
    final Color border =
        active ? cs.primary : Colors.white.withValues(alpha: 0.25);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
        boxShadow: active
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard(
      {required this.title, required this.start, required this.end});
  final String title;
  final DateTime start;
  final DateTime end;

  String _fmt(DateTime d) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant.withOpacity(.6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('${_fmt(start)} — ${_fmt(end)}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
