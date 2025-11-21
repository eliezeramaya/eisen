import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/core/ui/ui_typography.dart' as typography;
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_debug.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/_last_moved_highlight_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class TreemapCanvas extends StatefulWidget {
  const TreemapCanvas({
    super.key,
    required this.tasks,
    required this.layout,
    this.suggestedIds,
    this.presentQuadrant,
    this.onTap,
    this.onDropToQuadrant,
    this.onDoubleTapQuadrant,
    this.zoom,
    this.onEditTask,
    this.onMarkDone,
    this.inlineEditId,
    this.onInlineSubmit,
    this.onInlineCancel,
    this.minimal = false,
    this.compact = false,
    this.selectedId,
    this.textScale = 1.0,
    this.lastMovedTaskId,
    this.loading = false,
  });
  final List<Task> tasks;
  final List<TreemapRect> layout;
  final Set<String>? suggestedIds;
  final Quadrant? presentQuadrant;
  final void Function(String? id)? onTap;
  final void Function(String id, Quadrant q)? onDropToQuadrant;
  final void Function(Quadrant q)? onDoubleTapQuadrant;
  final Quadrant? zoom;
  final void Function(String id)? onEditTask;
  final void Function(String id)? onMarkDone;
  final String? inlineEditId;
  final void Function(String id, String title)? onInlineSubmit;
  final void Function(String id)? onInlineCancel;
  final bool minimal;
  final bool compact;
  final String? selectedId;
  // User/app text scale multiplier applied to treemap labels
  final double textScale;
  final String? lastMovedTaskId;
  final bool loading;

  @override
  State<TreemapCanvas> createState() => _TreemapCanvasState();
}

class _TreemapCanvasState extends State<TreemapCanvas>
    with TickerProviderStateMixin {
  String? _draggingId;
  Offset? _lastPos;
  Quadrant? _hoverQuadrant;
  late final AnimationController _anim;
  double _t = 1.0;
  Map<String, Rect> _prevRects01 = {};
  Map<String, Rect> _nextRects01 = {};
  // Stable rect memo per task id (normalized 0..1). Updated on commit of transitions
  final Map<String, Rect> _lastStableRectById = {};
  // Fade-out states for removed tiles
  final Map<String, _OutroState> _pendingOutros = {};
  // Track ids that are appearing (for 0->1 alpha ramp)
  final Set<String> _appearingIds = <String>{};
  // Bump to force painter repaint when outros advance without layout animation
  int _outrosVersion = 0;
  final _inlineController = TextEditingController();
  final _inlineFocus = FocusNode();
  late final AnimationController _pulse;
  double _pulseT = 0.0;
  Quadrant? _pulseQuadrant;
  // Increments whenever a new layout list is provided, used to invalidate path cache
  int _layoutVersion = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: AnimTokens.layout)
      ..addListener(() {
        setState(() => _t = _anim.value);
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          // Commit next rects as new stable positions
          for (final e in _nextRects01.entries) {
            _lastStableRectById[e.key] = e.value;
          }
          // GC stale
          final alive = _nextRects01.keys.toSet();
          _lastStableRectById.removeWhere((id, _) => !alive.contains(id));
          _appearingIds.clear();
        }
      });
    _pulse = AnimationController(vsync: this, duration: AnimTokens.pulse)
      ..addListener(() {
        setState(() => _pulseT = _pulse.value);
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _pulseQuadrant = null);
        }
      });
    // Initialize next rects with initial layout
    _nextRects01 = _rectMap(widget.layout);
    _t = 1.0;
    // Initialize stable memo on first mount
    _lastStableRectById
      ..clear()
      ..addAll(_nextRects01);
  }

  @override
  void didUpdateWidget(covariant TreemapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.layout, widget.layout)) {
      final newRects = _rectMap(widget.layout);

      if (_nextRects01.isEmpty) {
        // First layout: no animation. Commit as stable directly.
        _nextRects01 = newRects;
        _lastStableRectById
          ..clear()
          ..addAll(newRects);
        _appearingIds.clear();
        _t = 1.0;
      } else {
        // Build interpolation maps using last stable rects when possible.
        final fromRects = <String, Rect>{};
        final toRects = <String, Rect>{};
        _appearingIds.clear();

        // Appearing/updated ids (present in next)
        for (final entry in newRects.entries) {
          final id = entry.key;
          final toR = entry.value;
          final fromR = _lastStableRectById[id] ?? _prevRects01[id];
          if (fromR != null) {
            fromRects[id] = fromR;
          } else {
            // Seed around target for smooth grow-in
            fromRects[id] = _seedFromTarget(toR, seedScale: 0.85);
            _appearingIds.add(id);
          }
          toRects[id] = toR;
        }

        // Removed ids: present before or as stable but not in next
        final prevIds = {..._prevRects01.keys, ..._lastStableRectById.keys};
        final removed = <String>{
          for (final id in prevIds)
            if (!newRects.containsKey(id)) id,
        };
        if (removed.isNotEmpty) {
          // Create fast fade-out outros using last stable geometry, color by quadrant from old layout if available
          final oldById = {for (final tr in oldWidget.layout) tr.task.id: tr};
          final now = DateTime.now();
          for (final id in removed) {
            final r = _lastStableRectById[id] ?? _prevRects01[id];
            if (r == null) continue;
            final tr = oldById[id];
            final q = tr?.task.quadrant;
            _pendingOutros[id] = _OutroState(
              rect: r,
              quadrant: q,
              startedAt: now,
              duration: const Duration(milliseconds: 150),
            );
          }
          // Ensure painter repaints outros even if no anim would run
          _outrosVersion++;
        }

        _prevRects01 = fromRects;
        _nextRects01 = toRects;

        // Restart animation
        _anim.stop();
        _anim.forward(from: 0);
      }
      // New layout list provided -> bump layout version to invalidate path cache
      _layoutVersion++;
      // Prune stable rects for ids no longer present
      final alive = newRects.keys.toSet();
      _lastStableRectById.removeWhere((id, _) => !alive.contains(id));
    }
    if (oldWidget.inlineEditId != widget.inlineEditId) {
      if (widget.inlineEditId != null) {
        // Prefill with current title (defensive)
        final idx = widget.tasks.indexWhere((e) => e.id == widget.inlineEditId);
        if (idx != -1) {
          final t = widget.tasks[idx];
          _inlineController.text = t.title;
        } else {
          _inlineController.text = '';
        }
        // focus shortly after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _inlineFocus.requestFocus();
        });
      } else {
        _inlineController.clear();
        _inlineFocus.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _pulse.dispose();
    _inlineController.dispose();
    _inlineFocus.dispose();
    super.dispose();
  }

  // Create a seed rect centered on target for new/returning items
  Rect _seedFromTarget(Rect to, {double seedScale = 0.85}) {
    final s = seedScale.clamp(0.2, 1.0);
    final w = to.width * s;
    final h = to.height * s;
    final cx = to.left + to.width * 0.5;
    final cy = to.top + to.height * 0.5;
    return Rect.fromLTWH(cx - w * 0.5, cy - h * 0.5, w, h);
  }

  Rect _lerpSnapRect(Rect a, Rect b, double t) {
    return Rect.lerp(a, b, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Provide a safe fallback for theme tokens so tests that don't install the app theme don't crash
        final glassTokens = Theme.of(context).extension<GlassTokens>() ??
            const GlassTokens(
              glassBg: Color(0xCCFFFFFF),
              blur: 12,
              radius: 20,
              q1: Color(0xFFD92D20),
              q2: Color(0xFF12B76A),
              q3: Color(0xFFF79009),
              q4: Color(0xFF2E90FA),
              halo: Color(0x332E90FA),
            );
        final overlay = <Widget>[];
        // If layout already contains stack tiles, skip overlay fallback
        final hasStackTiles = widget.layout.any(
          (e) => e.stackChildren.isNotEmpty,
        );
        // Compute tiny tiles per quadrant only if no integrated stacks present
        // Adjust minimum area threshold based on density mode to make the change noticeable
        final double minAreaPx =
            LayoutConstants.minTileAreaPx * (widget.compact ? 0.7 : 1.0);
        final tinyByQ = <Quadrant, List<TreemapRect>>{
          Quadrant.q1: [],
          Quadrant.q2: [],
          Quadrant.q3: [],
          Quadrant.q4: [],
        };
        if (!hasStackTiles) {
          for (final tr in widget.layout) {
            final r = _px(tr.rect01, size);
            // Represent as tiny if smaller than min interactive area (squared)
            if (r.width < LayoutConstants.minTileSize ||
                r.height < LayoutConstants.minTileSize ||
                r.width * r.height < minAreaPx) {
              tinyByQ[tr.task.quadrant]!.add(tr);
            }
          }
        }
        if (widget.onEditTask != null || widget.onMarkDone != null) {
          // Adjust button visibility threshold by density
          final double minAreaForButtons =
              LayoutConstants.minAreaForButtons * (widget.compact ? 0.85 : 1.0);
          for (final tr in widget.layout) {
            final r = _px(tr.rect01, size);
            // Show edit button only for reasonably large tiles
            if (r.width * r.height < minAreaForButtons) continue;
            const btn = 28.0;
            if (widget.onMarkDone != null) {
              overlay.add(
                Positioned(
                  left: r.left + 6,
                  top: r.top + 6,
                  width: btn,
                  height: btn,
                  child: _CheckDot(
                    onPressed: () => widget.onMarkDone?.call(tr.task.id),
                    minimal: widget.minimal,
                  ),
                ),
              );
            }
            overlay.add(
              Positioned(
                left: r.right - btn - 6,
                top: r.top + 6,
                width: btn,
                height: btn,
                child: _EditDot(
                  onPressed: () => widget.onEditTask?.call(tr.task.id),
                ),
              ),
            );
          }
        }

        // Add non-interactive testing overlays: tile keys and quadrant dropzones (debug only)
        assert(() {
          // Current interpolated rects for tiles
          final curveT = AnimTokens.curve.transform(_t.clamp(0.0, 1.0));
          for (final tr in widget.layout) {
            final id = tr.task.id;
            final r01From = _prevRects01[id] ?? tr.rect01;
            final r01To = _nextRects01[id] ?? tr.rect01;
            final r01 = _lerpSnapRect(r01From, r01To, curveT);
            final r = _px(r01, size);
            if (r.width >= LayoutConstants.minTileSize &&
                r.height >= LayoutConstants.minTileSize) {
              overlay.add(
                Positioned(
                  key: ValueKey('tile_$id'),
                  left: r.left,
                  top: r.top,
                  width: r.width,
                  height: r.height,
                  child: const IgnorePointer(child: SizedBox.expand()),
                ),
              );
            }
          }
          // Quadrant dropzone keys for testing
          // Quadrant dropzone keys for testing
          final halfW = size.width / 2;
          final halfH = size.height / 2;
          Rect _quadRect(Quadrant q) {
            switch (q) {
              case Quadrant.q1:
                return Rect.fromLTWH(0, 0, halfW, halfH);
              case Quadrant.q2:
                return Rect.fromLTWH(halfW, 0, halfW, halfH);
              case Quadrant.q3:
                return Rect.fromLTWH(0, halfH, halfW, halfH);
              case Quadrant.q4:
                return Rect.fromLTWH(halfW, halfH, halfW, halfH);
            }
          }
          for (final q in Quadrant.values) {
            final qRect = _quadRect(q);
            overlay.add(
              Positioned(
                key: ValueKey('quadrant_${q.name}_dropzone'),
                left: qRect.left,
                top: qRect.top,
                width: qRect.width,
                height: qRect.height,
                child: const IgnorePointer(child: SizedBox.expand()),
              ),
            );
          }
          return true;
        }());

        return Stack(
          children: [
            Positioned.fill(
              child: MouseRegion(
                cursor: _draggingId != null
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    final id = _hitTest(d.localPosition, size);
                    if (id != null) {
                      final idx = widget.layout.indexWhere(
                        (e) => e.task.id == id,
                      );
                      final tr = idx == -1 ? null : widget.layout[idx];
                      if (tr != null && tr.stackChildren.isNotEmpty) {
                        // Open stack sheet for this quadrant
                        Telemetry.stackOpen(
                          tr.task.quadrant.name,
                          tr.stackChildren.length,
                        );
                        _openStackSheet(
                          context,
                          tr.task.quadrant,
                          tr.stackChildren,
                        );
                        return;
                      }
                      Telemetry.tileTap(id);
                    }
                    widget.onTap?.call(id);
                  },
                  onTapUp: (d) {
                    final id = _hitTest(d.localPosition, size);
                    if (id != null) {
                      final idx = widget.layout.indexWhere(
                        (e) => e.task.id == id,
                      );
                      final tr = idx == -1 ? null : widget.layout[idx];
                      if (tr != null && tr.stackChildren.isNotEmpty) {
                        Telemetry.stackOpen(
                          tr.task.quadrant.name,
                          tr.stackChildren.length,
                        );
                        _openStackSheet(
                          context,
                          tr.task.quadrant,
                          tr.stackChildren,
                        );
                        return;
                      }
                      Telemetry.tileTap(id);
                    }
                    widget.onTap?.call(id);
                  },
                  onDoubleTapDown: (d) {
                    final q = _quadrantAt(d.localPosition, size);
                    if (q != null) {
                      Telemetry.zoomQuadrant(q.name);
                      widget.onDoubleTapQuadrant?.call(q);
                    }
                  },
                  onLongPressStart: (d) {
                    final id = _hitTest(d.localPosition, size);
                    if (id == null) return;
                    final idx = widget.tasks.indexWhere((e) => e.id == id);
                    final t = idx == -1 ? null : widget.tasks[idx];
                    final msg = t == null
                        ? 'Tarea'
                        : '${t.title} • P${t.priority} • ${t.minutes}m';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        duration: const Duration(milliseconds: 1200),
                      ),
                    );
                  },
                  onPanStart: (d) {
                    if (widget.inlineEditId != null) {
                      return; // disable drag while editing
                    }
                    setState(() {
                      _draggingId = _hitTest(d.localPosition, size);
                      _lastPos = d.localPosition;
                      _hoverQuadrant = _quadrantAt(_lastPos!, size);
                    });
                    if (_draggingId != null) {
                      Telemetry.tileDragStart(_draggingId!);
                    }
                  },
                  onPanEnd: (d) {
                    if (widget.inlineEditId == null &&
                        _draggingId != null &&
                        widget.zoom == null) {
                      final q = _quadrantAt(_lastPos ?? Offset.zero, size);
                      if (q != null) {
                        widget.onDropToQuadrant?.call(_draggingId!, q);
                        Telemetry.tileDrop(_draggingId!, q.name);
                        _pulseQuadrant = q;
                        _pulse.forward(from: 0);
                        HapticFeedback.lightImpact();
                      }
                    }
                    setState(() {
                      _draggingId = null;
                      _hoverQuadrant = null;
                      _lastPos = null;
                    });
                  },
                  onPanUpdate: (d) {
                    if (widget.inlineEditId != null) return;
                    setState(() {
                      _lastPos = d.localPosition;
                      _hoverQuadrant = _quadrantAt(_lastPos!, size);
                    });
                  },
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: _TreemapPainter(
                            widget.layout,
                            draggingId: _draggingId,
                            pointer: _lastPos,
                            hoverQuadrant:
                                widget.zoom == null ? _hoverQuadrant : null,
                            presentQuadrant: widget.presentQuadrant,
                            zoom: widget.zoom,
                            prevRects01: _prevRects01,
                            nextRects01: _nextRects01,
                            t: _t,
                            tokens: glassTokens,
                            minimal: widget.minimal,
                            pulseQuadrant: _pulseQuadrant,
                            pulseT: _pulseT,
                            suggested: widget.suggestedIds,
                            layoutVersion: _layoutVersion,
                            selectedId: widget.selectedId,
                            appearingIds: _appearingIds,
                            outros: _pendingOutros,
                            outrosVersion: _outrosVersion,
                            outlineColor: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.28),
                            tileBorderColor: UiTokens.stroke(
                              Theme.of(context).colorScheme,
                            ),
                            onSurface: Theme.of(context).colorScheme.onSurface,
                            onSurfaceVariant: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            tileFillColor: UiTokens.fill(
                              Theme.of(context).colorScheme,
                            ),
                            textScale: widget.textScale,
                          ),
                          isComplex: true,
                          willChange: true,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      if (widget.lastMovedTaskId != null)
                        LastMovedHighlightOverlay(
                          id: widget.lastMovedTaskId!,
                          layout: widget.layout,
                          rectMap: _nextRects01,
                          size: size,
                        ),
                      if (widget.loading)
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: 0.06,
                            duration:
                                const Duration(milliseconds: 180),
                            child: ColoredBox(
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Stack overlays per quadrant (place at bottom-right of each quadrant)
            if (!hasStackTiles)
              ...Quadrant.values.map((q) {
                final count = tinyByQ[q]!.length;
                if (count == 0) return const SizedBox.shrink();
                const m = 16.0;
                // Compute anchors so the chip sits at the bottom-right of each quadrant
                double? right;
                double? bottom;
                switch (q) {
                  case Quadrant.q1:
                    right = size.width / 2 +
                        m; // anchor to Q1 right edge minus margin
                    bottom = size.height / 2 +
                        m; // anchor to Q1 bottom edge minus margin
                    break;
                  case Quadrant.q2:
                    right = m; // right edge of parent minus margin
                    bottom = size.height / 2 + m; // Q2 bottom edge minus margin
                    break;
                  case Quadrant.q3:
                    right = size.width / 2 + m; // Q3 right edge minus margin
                    bottom = m; // parent bottom minus margin
                    break;
                  case Quadrant.q4:
                    right = m;
                    bottom = m;
                    break;
                }
                return Positioned(
                  key: ValueKey('stack_${q.name}'),
                  right: right,
                  bottom: bottom,
                  child: RepaintBoundary(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Telemetry.stackOpen(q.name, count);
                          _openStackSheet(
                            context,
                            q,
                            tinyByQ[q]!.map((e) => e.task).toList(),
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          LayoutConstants.tileBorderRadius,
                        ),
                        child: Builder(
                          builder: (context) {
                            // Render as a small square tile, styled like other tiles
                            final Color qColor;
                            switch (q) {
                              case Quadrant.q1:
                                qColor = glassTokens.q1;
                                break;
                              case Quadrant.q2:
                                qColor = glassTokens.q2;
                                break;
                              case Quadrant.q3:
                                qColor = glassTokens.q3;
                                break;
                              case Quadrant.q4:
                                qColor = glassTokens.q4;
                                break;
                            }
                            final tileSize = LayoutConstants
                                .minTileSize; // square small size
                            final fillAlpha = widget.minimal ? 0.25 : 0.18;
                            final borderColor = widget.minimal
                                ? Colors.black.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.18);
                            // Use dark gray text in minimal mode for better visibility on light surfaces
                            final textColor = widget.minimal
                                ? const Color(0xFF424242)
                                : Colors.white;
                            return Container(
                              width: tileSize,
                              height: tileSize,
                              decoration: BoxDecoration(
                                color: qColor.withValues(alpha: fillAlpha),
                                borderRadius: BorderRadius.circular(
                                  LayoutConstants.tileBorderRadius,
                                ),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '+$count',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: LayoutConstants.stackBadgeFontSize,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),
            if (widget.inlineEditId != null) _buildInlineEditor(context, size),
            ...overlay,
          ],
        );
      },
    );
  }

  String? _hitTest(Offset pos, Size size) {
    // Ensure hit-testing uses same transform as painting: use layout rects scaled to pixels
    for (final tr in widget.layout) {
      final r = _px(tr.rect01, size);
      // enforce minimum interactive size
      if (r.width < LayoutConstants.minTileSize ||
          r.height < LayoutConstants.minTileSize) {
        continue;
      }
      if (r.contains(pos)) return tr.task.id;
    }
    return null;
  }

  Quadrant? _quadrantAt(Offset pos, Size size) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final left = pos.dx < halfW;
    final top = pos.dy < halfH;
    if (left && top) return Quadrant.q1;
    if (!left && top) return Quadrant.q2;
    if (left && !top) return Quadrant.q3;
    return Quadrant.q4;
  }

  Rect _px(Rect r01, Size size) => Rect.fromLTWH(
        r01.left * size.width,
        r01.top * size.height,
        r01.width * size.width,
        r01.height * size.height,
      );

  Map<String, Rect> _rectMap(List<TreemapRect> layout) {
    final m = <String, Rect>{};
    // Reorder paint z-order: if a suggested id exists in a tie group (±5% area)
    // within its quadrant, paint it last so it sits "on top". Geometry is not changed.
    final paintList = reorderForTieBreak(layout, widget.suggestedIds);
    for (final tr in paintList) {
      m[tr.task.id] = tr.rect01;
    }
    return m;
  }

  // ignore: unused_element
  Offset _stackOverlayPosition(Quadrant q, Size size) {
    // Position near top-left of each quadrant, with margin to avoid banner
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    const m = 16.0; // increased margin
    switch (q) {
      case Quadrant.q1:
        return const Offset(16, 16); // avoid banner at 8,8
      case Quadrant.q2:
        return Offset(halfW + m, 16);
      case Quadrant.q3:
        return Offset(16, halfH + m);
      case Quadrant.q4:
        return Offset(halfW + m, halfH + m);
    }
  }

  void _openStackSheet(BuildContext context, Quadrant q, List<Task> tasks) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) {
        return SafeArea(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final t = tasks[i];
              return ListTile(
                title: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'P${t.priority} • ${t.minutes}m${t.due != null ? ' • due' : ''}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: '+15m',
                      icon: const Icon(Icons.add_alarm),
                      onPressed: widget.onEditTask == null
                          ? null
                          : () => widget.onEditTask!(t.id),
                    ),
                    PopupMenuButton<Quadrant>(
                      tooltip: 'Mover a',
                      onSelected: (dest) =>
                          widget.onDropToQuadrant?.call(t.id, dest),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: Quadrant.q1,
                          child: Text('Q1'),
                        ),
                        const PopupMenuItem(
                          value: Quadrant.q2,
                          child: Text('Q2'),
                        ),
                        const PopupMenuItem(
                          value: Quadrant.q3,
                          child: Text('Q3'),
                        ),
                        const PopupMenuItem(
                          value: Quadrant.q4,
                          child: Text('Q4'),
                        ),
                      ],
                      child: const Icon(Icons.open_in_full),
                    ),
                    IconButton(
                      tooltip: 'Marcar done',
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => widget.onEditTask?.call(t.id),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// (removed unused _buildTagChip helper)

extension on _TreemapCanvasState {
  Widget _buildInlineEditor(BuildContext context, Size size) {
    final id = widget.inlineEditId!;
    final r01 = _nextRects01[id] ?? _prevRects01[id];
    if (r01 == null) return const SizedBox.shrink();
    final rect = _px(r01, size).deflate(6);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: 56,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.edit, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _inlineController,
                  focusNode: _inlineFocus,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Título de la tarea…',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isEmpty) {
                      widget.onInlineCancel?.call(id);
                    } else {
                      widget.onInlineSubmit?.call(id, value.trim());
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onInlineCancel?.call(id),
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onPressed: () {
                  final value = _inlineController.text.trim();
                  if (value.isEmpty) {
                    widget.onInlineCancel?.call(id);
                  } else {
                    widget.onInlineSubmit?.call(id, value);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDot extends StatelessWidget {
  const _EditDot({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            splashRadius: 16,
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            tooltip: 'Edit task',
          ),
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.onPressed, required this.minimal});
  final VoidCallback onPressed;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: minimal
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: minimal
                  ? Colors.black26
                  : Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            splashRadius: 16,
            icon: Icon(
              Icons.check,
              size: 16,
              color: minimal ? Colors.black : Colors.white,
            ),
            tooltip: 'Completar',
          ),
        ),
      ),
    );
  }
}

class _TreemapPainter extends CustomPainter {
  _TreemapPainter(
    this.layout, {
    this.draggingId,
    this.pointer,
    this.hoverQuadrant,
    this.presentQuadrant,
    this.zoom,
    required this.prevRects01,
    required this.nextRects01,
    required this.t,
    required this.tokens,
    required this.minimal,
    this.pulseQuadrant,
    this.pulseT = 0.0,
    this.suggested,
    required this.layoutVersion,
    this.selectedId,
    this.appearingIds = const <String>{},
    this.outros = const <String, _OutroState>{},
    this.outrosVersion = 0,
    required this.outlineColor,
    required this.tileBorderColor,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.tileFillColor,
    this.textScale = 1.0,
  });
  final List<TreemapRect> layout;
  final String? draggingId;
  final Offset? pointer;
  final Quadrant? hoverQuadrant;
  final Quadrant? presentQuadrant;
  final Quadrant? zoom;
  final Map<String, Rect> prevRects01;
  final Map<String, Rect> nextRects01;
  final double t; // 0..1
  final GlassTokens tokens;
  final bool minimal;
  final Quadrant? pulseQuadrant;
  final double pulseT; // 0..1
  final Set<String>? suggested;
  final int layoutVersion;
  final String? selectedId;
  final Set<String> appearingIds;
  final Map<String, _OutroState> outros;
  final int outrosVersion;
  final Color outlineColor;
  final Color tileBorderColor;
  final Color tileFillColor;
  final Color onSurface;
  final Color onSurfaceVariant;
  final double textScale;

  /// Tile path cache for performance optimization.
  ///
  /// Memoizes rounded rectangle paths by (task.id + rect01 hash) to avoid
  /// redundant path calculations when layout is stable. Cache is static and
  /// shared across painter instances.
  ///
  /// Benefits:
  /// - Reduces CPU overhead during animation frames
  /// - Prevents path recalculation for stable tiles
  /// - Improves paint performance when only dragging/hovering changes
  ///
  /// Cache invalidation: Automatic via key = '${task.id}_${rect.hashCode}'
  /// When rect changes, new key is generated and old entry is orphaned.
  static final Map<String, Path> _pathCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final double gap = LayoutConstants.tileGap; // uniform gap between tiles

    final halfW = size.width / 2;
    final halfH = size.height / 2;

    // Only draw center cross when NOT zoomed into a single quadrant
    if (zoom == null) {
      // Draw subtle quadrant grid (center cross) so the matrix is visible even with no tiles
      final centerLine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor;
      // Vertical center line
      canvas.drawLine(Offset(halfW, 0), Offset(halfW, size.height), centerLine);
      // Horizontal center line
      canvas.drawLine(Offset(0, halfH), Offset(size.width, halfH), centerLine);
    } else {
      // When zoomed, draw corner indicators to show quadrant position
      _drawQuadrantCornerIndicators(canvas, size, zoom!);
    }

    // Quadrant labels when no tiles or demo mode
    if (layout.isEmpty) {
      const labels = [
        'Q1\nUrgente\nImportante',
        'Q2\nNo Urgente\nImportante',
        'Q3\nUrgente\nNo Importante',
        'Q4\nNo Urgente\nNo Importante',
      ];
      final centers = [
        Offset(halfW / 2, halfH / 2),
        Offset(halfW + halfW / 2, halfH / 2),
        Offset(halfW / 2, halfH + halfH / 2),
        Offset(halfW + halfW / 2, halfH + halfH / 2),
      ];
      for (int i = 0; i < 4; i++) {
        final tp = _textPainter(
          labels[i],
          Rect.fromCenter(center: centers[i], width: halfW, height: halfH),
          16,
          FontWeight.w600,
          textColor: minimal ? const Color(0xFF424242) : Colors.white,
          maxLines: 3,
        );
        tp.paint(
          canvas,
          Offset(centers[i].dx - tp.width / 2, centers[i].dy - tp.height / 2),
        );
      }
    }

    // Debug: quadrant bounds in blue (disabled in minimal to keep visuals stable)
    if (debugTreemap && !minimal) {
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(0, 0, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(halfW, 0, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(0, halfH, halfW, halfH),
      );
      TreemapDebugOverlay.drawQuadrantBounds(
        canvas,
        Rect.fromLTWH(halfW, halfH, halfW, halfH),
      );
      // HUD: area sums per quadrant
      final quadRects = [
        Rect.fromLTWH(0, 0, halfW, halfH),
        Rect.fromLTWH(halfW, 0, halfW, halfH),
        Rect.fromLTWH(0, halfH, halfW, halfH),
        Rect.fromLTWH(halfW, halfH, halfW, halfH),
      ];
      for (int i = 0; i < 4; i++) {
        final q = Quadrant.values[i];
        final areaSum = layout
            .where((e) => e.task.quadrant == q)
            .fold<double>(0, (a, e) => a + (e.rect01.width * e.rect01.height));
        final quadArea = 0.5 * 0.5; // normalized
        final pct = (areaSum / quadArea * 100).clamp(0.0, 999.0);
        final label = '${q.name}: ${pct.toStringAsFixed(1)}%';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 10, color: Colors.blueAccent),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = Offset(quadRects[i].left + 6, quadRects[i].top + 6);
        tp.paint(canvas, pos);
      }
    }

    // Removed present quadrant glow to avoid confusing highlight

    // Highlight hovered quadrant as a subtle overlay (takes precedence)
    if (hoverQuadrant != null) {
      final qRect = _quadrantRect(hoverQuadrant!, size);
      final qColor = minimal ? Colors.black : _byQuadrant(hoverQuadrant!);
      final overlay = Paint()
        ..style = PaintingStyle.fill
        ..color = minimal
            ? Colors.black.withValues(alpha: 0.06)
            : qColor.withValues(alpha: 0.08);
      canvas.drawRect(qRect, overlay);

      // Soft border glow
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..color = minimal
            ? Colors.black.withValues(alpha: 0.25)
            : qColor.withValues(alpha: 0.25)
        ..strokeWidth = 2;
      canvas.drawRect(qRect.deflate(1), border);
    }

    final curveT = AnimTokens.curve.transform(t.clamp(0.0, 1.0));
    // Drop pulse feedback
    if (pulseQuadrant != null && pulseT > 0) {
      final qRect = _quadrantRect(pulseQuadrant!, size);
      final c = qRect.center;
      final color = minimal ? Colors.black : _byQuadrant(pulseQuadrant!);
      final r = ui.lerpDouble(8, 28, Curves.easeOut.transform(pulseT))!;
      final a = (1.0 - pulseT).clamp(0.0, 1.0);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.withValues(alpha: minimal ? 0.35 * a : 0.45 * a);
      canvas.drawCircle(c, r, ring);
    }
    // Prepare shelf clusters for debug overlay
    if (debugTreemap && !minimal && layout.isNotEmpty) {
      final byQ = <Quadrant, List<Rect>>{
        for (final q in Quadrant.values) q: [],
      };
      for (final tr in layout) {
        final rr = Rect.fromLTWH(
          tr.rect01.left * size.width,
          tr.rect01.top * size.height,
          tr.rect01.width * size.width,
          tr.rect01.height * size.height,
        );
        byQ[tr.task.quadrant]!.add(rr);
      }
      for (final q in Quadrant.values) {
        final shelves = _clusterShelves(byQ[q]!);
        for (final s in shelves) {
          TreemapDebugOverlay.drawShelf(canvas, s);
        }
      }
    }

    for (final tr in layout) {
      final id = tr.task.id;
      final r01From = prevRects01[id] ?? tr.rect01;
      final r01To = nextRects01[id] ?? tr.rect01;
      final r01 = Rect.lerp(r01From, r01To, curveT)!;
      final r0 = Rect.fromLTWH(
        r01.left * size.width,
        r01.top * size.height,
        r01.width * size.width,
        r01.height * size.height,
      );
      final r = _snapRect(r0);
      // Flat design: do not color tiles by quadrant

      // If dragging this tile, render it "lifted"
      final bool isDragging = tr.task.id == draggingId;
      Rect drawRect;
      if (isDragging) {
        // Scale around center and slightly offset towards pointer
        final scaled = _scaleRect(r, 1.04);
        Offset shift = Offset.zero;
        if (pointer != null) {
          final v = pointer! - scaled.center;
          final len = v.distance;
          final maxShift = 6.0;
          shift += len > 0
              ? Offset(v.dx / len * maxShift, v.dy / len * maxShift)
              : Offset.zero;
        }
        // Magnetism: bias towards center of hovered quadrant
        if (hoverQuadrant != null) {
          final qCenter = _quadrantRect(hoverQuadrant!, size).center;
          final mv = qCenter - scaled.center;
          final mlen = mv.distance;
          final mMax = 8.0;
          final bias = 0.12; // fraction towards center
          final mshift = mlen > 0
              ? Offset(mv.dx / mlen * mMax * bias, mv.dy / mlen * mMax * bias)
              : Offset.zero;
          shift += mshift;
        }
        drawRect = scaled.shift(shift);
        // No shadows in flat design
      } else {
        drawRect = r;
        // No shadows in flat design
      }
      // Deflate to create a gutter around each tile so rounded borders are visible
      // Clamp gutter so we don't invert tiny rects, then snap to pixel grid to avoid gaps
      final safeGap = math.min(
        gap,
        math.max(0.0, math.min(drawRect.width, drawRect.height) * 0.5 - 0.5),
      );
      drawRect = _snapRect(drawRect.deflate(safeGap));
      // Single geometry: flat fill + 1dp stroke
      final rr = RRect.fromRectAndRadius(
        drawRect,
        Radius.circular(UiTokens.tileRadius),
      );
      final fillColor = tileFillColor;
      paint
        ..style = PaintingStyle.fill
        ..color = fillColor;
      canvas.drawRRect(rr, paint);
      paint
        ..style = PaintingStyle.stroke
        ..color = tileBorderColor
        ..strokeWidth = UiTokens.tileStroke;
      canvas.drawRRect(rr, paint);

      // If this is a stack tile, render a centered +N label and skip details
      if (tr.stackChildren.isNotEmpty) {
        final label = '+${tr.stackChildren.length}';
        if (minimal) {
          final tp = _textPainter(
            label,
            drawRect,
            12,
            FontWeight.w700,
            textColor: onSurface,
          );
          tp.paint(
            canvas,
            Offset(
              drawRect.right - tp.width - 6,
              drawRect.bottom - tp.height - 4,
            ),
          );
        } else {
          final tp = _textPainter(
            label,
            drawRect,
            14,
            FontWeight.w700,
            textColor: onSurface,
          );
          tp.paint(
            canvas,
            Offset(
              drawRect.center.dx - tp.width / 2,
              drawRect.center.dy - tp.height / 2,
            ),
          );
        }
        continue;
      }

      // Title + metadata (minimal: show only on interaction)
      final area = drawRect.width * drawRect.height;
      final availableHeight = drawRect.height - 12; // padding top+bottom
      double currentY = drawRect.top + 6;

      final canShowTitle = debugTreemap || availableHeight > 18.0;
      final pointerInside = pointer != null && drawRect.contains(pointer!);
      final isSelected = selectedId != null && selectedId == tr.task.id;
      final showLabel = !minimal || isDragging || pointerInside || isSelected;

      // Calculate priority/time metadata height for bottom positioning
      final responsiveMetaSize =
          typography.metaFontSize(size).toDouble() * textScale;
      final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
      final metaPainter = _textPainter(
        meta,
        drawRect,
        responsiveMetaSize,
        FontWeight.w500,
        alpha: 0.95,
        maxLines: 1,
        textColor: onSurfaceVariant,
      );
      final metaHeight = metaPainter.height;

      // Reserve space at bottom for priority/time (always shown if space allows)
      final reserveBottomSpace = showLabel && area > 12000 && !debugTreemap;
      final bottomReserved = reserveBottomSpace ? metaHeight + 8 : 0.0;

      // Title
      if (showLabel && canShowTitle) {
        final responsiveTitleSize =
            (debugTreemap ? 16.0 : typography.titleFontSize(size).toDouble()) *
                textScale;
        final tp = _textPainter(
          tr.task.title,
          drawRect,
          responsiveTitleSize,
          FontWeight.w700,
          textColor: onSurface,
          maxLines: debugTreemap ? 3 : 1,
        );
        tp.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp.height + 2;
      }

      // Notes preview (if large size and has notes) - now goes after title
      if (showLabel &&
          area > 26000 &&
          tr.task.notes != null &&
          tr.task.notes!.isNotEmpty &&
          currentY + 14 < drawRect.bottom - bottomReserved - 6 &&
          !debugTreemap) {
        final responsiveNotesSize =
            typography.metaFontSize(size).toDouble() * textScale;
        final notesPreview = tr.task.notes!.length > 50
            ? '${tr.task.notes!.substring(0, 50)}...'
            : tr.task.notes!;
        final tp3 = _textPainter(
          notesPreview,
          drawRect,
          responsiveNotesSize,
          FontWeight.w400,
          alpha: minimal ? 0.9 : 0.85,
          maxLines: 2,
          textColor: minimal ? const Color(0xFF424242) : Colors.white,
        );
        tp3.paint(canvas, Offset(drawRect.left + 8, currentY));
      }

      // Priority and time - ALWAYS at bottom if space allows
      if (reserveBottomSpace) {
        final bottomY = drawRect.bottom - metaHeight - 6;
        metaPainter.paint(canvas, Offset(drawRect.left + 8, bottomY));
      }

      // Removed quadrant color indicator for flat design

      // Removed: Suggested by bandit badge (star) - flat design
      // if (suggested?.contains(tr.task.id) == true) {
      //   final star = _textPainter('★', drawRect, 12, FontWeight.w700, alpha: minimal ? 0.95 : 0.9, textColor: minimal ? Colors.black : Colors.white);
      //   star.paint(canvas, Offset(drawRect.left + 6, drawRect.top + 4));
      // }

      // Debug labels for each tile
      if (debugTreemap && !minimal) {
        final area =
            (drawRect.width * drawRect.height) / (size.width * size.height);
        final ratio = drawRect.width == 0 || drawRect.height == 0
            ? 0.0
            : (drawRect.width / drawRect.height).abs();
        final rr = ratio < 1 ? 1 / (ratio == 0.0 ? 1.0 : ratio) : ratio;
        TreemapDebugOverlay.labelTile(canvas, drawRect, tr.task.id, area, rr);
      }

      // Draw fade-out outros on top
      if (outros.isNotEmpty) {
        final now = DateTime.now();
        for (final entry in outros.entries) {
          final o = entry.value;
          final prog = o.progress(now);
          if (prog >= 1.0) continue;
          final alpha = (1.0 - prog).clamp(0.0, 1.0);
          final r0 = Rect.fromLTWH(
            o.rect.left * size.width,
            o.rect.top * size.height,
            o.rect.width * size.width,
            o.rect.height * size.height,
          );
          final r = _snapRect(r0);
          final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
          final baseColor = o.quadrant == null
              ? (minimal ? Colors.black : Colors.white)
              : _byQuadrant(o.quadrant!);
          final baseAlpha =
              (debugTreemap && !minimal) ? 0.28 : (minimal ? 0.25 : 0.18);
          final fill = Paint()
            ..style = PaintingStyle.fill
            ..color = baseColor.withValues(alpha: baseAlpha * alpha);
          canvas.drawRRect(rr, fill);
          final stroke = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (debugTreemap && !minimal) ? 2.0 : 1.0
            ..color = (minimal
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.18))
                .withValues(alpha: (minimal ? 0.20 : 0.18) * alpha);
          canvas.drawRRect(rr, stroke);
        }
      }
    }

    // Debug: visualize inferred shelves after tiles are drawn
    if (debugTreemap && !minimal) {
      final rects = <Rect>[];
      for (final tr in layout) {
        final r = Rect.fromLTWH(
          tr.rect01.left * size.width,
          tr.rect01.top * size.height,
          tr.rect01.width * size.width,
          tr.rect01.height * size.height,
        ).deflate(gap);
        rects.add(_snapRect(r));
      }
      for (final shelf in _clusterShelves(rects)) {
        TreemapDebugOverlay.drawShelf(canvas, shelf);
      }
    }
  }

  /// Determines whether the CustomPainter should repaint.
  ///
  /// Uses deep comparison of layout, animation state, and interaction state.
  /// Comparison is efficient because:
  /// - `layout` uses List equality (identity or content comparison)
  /// - `prevRects01`/`nextRects01` use Map equality
  /// - Primitive comparisons (t, pulseT, draggingId) are cheap
  ///
  /// Performance note: If adding complex overlays/tooltips per tile that cause
  /// jank, consider wrapping individual tiles with `RepaintBoundary` to isolate
  /// repaints. Only do this if profiling shows significant paint overhead.
  ///
  /// Path caching via `_pathCache` reduces redundant path calculations when
  /// layout is stable but other properties change (e.g., pointer movement).
  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) {
    final repaint = oldDelegate.layout != layout ||
        oldDelegate.draggingId != draggingId ||
        oldDelegate.pointer != pointer ||
        oldDelegate.hoverQuadrant != hoverQuadrant ||
        oldDelegate.t != t ||
        oldDelegate.suggested != suggested ||
        oldDelegate.pulseQuadrant != pulseQuadrant ||
        oldDelegate.pulseT != pulseT ||
        oldDelegate.prevRects01 != prevRects01 ||
        oldDelegate.nextRects01 != nextRects01 ||
        oldDelegate.layoutVersion != layoutVersion ||
        oldDelegate.tokens != tokens ||
        oldDelegate.minimal != minimal ||
        oldDelegate.zoom != zoom ||
        oldDelegate.outrosVersion != outrosVersion ||
        oldDelegate.outros.length != outros.length ||
        oldDelegate.appearingIds.length != appearingIds.length ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.tileBorderColor != tileBorderColor ||
        oldDelegate.tileFillColor != tileFillColor;

    // Invalidate path cache on layout version or key visual changes.
    if (oldDelegate.layoutVersion != layoutVersion ||
        oldDelegate.tokens != tokens ||
        oldDelegate.minimal != minimal ||
        oldDelegate.zoom != zoom) {
      _pathCache.clear();
    }
    return repaint;
  }

  @override
  bool shouldRebuildSemantics(covariant _TreemapPainter oldDelegate) =>
      oldDelegate.layout != layout;

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
        final nodes = <CustomPainterSemantics>[];
        for (final tr in layout) {
          final r = Rect.fromLTWH(
            tr.rect01.left * size.width,
            tr.rect01.top * size.height,
            tr.rect01.width * size.width,
            tr.rect01.height * size.height,
          );

          // Skip tiles with zero or negative dimensions (invisible to users)
          if (r.width <= 0 || r.height <= 0) continue;

          // Enhanced semantic label with complete task context
          final String label;
          if (tr.stackChildren.isNotEmpty) {
            // Stack tile: announce group size and quadrant
            label =
                'Group of ${tr.stackChildren.length + 1} tasks in quadrant ${tr.task.quadrant.name.toUpperCase()}, tap to expand';
          } else {
            // Individual tile: full task details for screen readers
            final parts = <String>[
              'Task: ${tr.task.title}',
              'Priority: ${tr.task.priority} out of 10',
              'Duration: ${tr.task.minutes} minutes',
              'Quadrant: ${_quadrantName(tr.task.quadrant)}',
            ];

            // Add due date if present
            if (tr.task.due != null) {
              final daysUntil = tr.task.due!.difference(DateTime.now()).inDays;
              if (daysUntil < 0) {
                parts.add('Overdue by ${-daysUntil} days');
              } else if (daysUntil == 0) {
                parts.add('Due today');
              } else if (daysUntil == 1) {
                parts.add('Due tomorrow');
              } else {
                parts.add('Due in $daysUntil days');
              }
            }

            // Add suggestion status
            if (suggested?.contains(tr.task.id) ?? false) {
              parts.add('Suggested task');
            }

            label = parts.join(', ');
          }

          nodes.add(
            CustomPainterSemantics(
              rect: r,
              properties: SemanticsProperties(
                label: label,
                button: true,
                textDirection: TextDirection.ltr,
                hint: 'Double tap to edit, or drag to move to another quadrant',
              ),
            ),
          );
        }
        return nodes;
      };

  /// Get human-readable quadrant name for semantics.
  String _quadrantName(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return 'Q1: Urgent and Important';
      case Quadrant.q2:
        return 'Q2: Not Urgent but Important';
      case Quadrant.q3:
        return 'Q3: Urgent but Not Important';
      case Quadrant.q4:
        return 'Q4: Not Urgent and Not Important';
    }
  }

  Color _byQuadrant(Quadrant q) {
    switch (q) {
      case Quadrant.q1:
        return tokens.q1;
      case Quadrant.q2:
        return tokens.q2;
      case Quadrant.q3:
        return tokens.q3;
      case Quadrant.q4:
        return tokens.q4;
    }
  }

  Rect _quadrantRect(Quadrant q, Size size) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    switch (q) {
      case Quadrant.q1:
        return Rect.fromLTWH(0, 0, halfW, halfH);
      case Quadrant.q2:
        return Rect.fromLTWH(halfW, 0, halfW, halfH);
      case Quadrant.q3:
        return Rect.fromLTWH(0, halfH, halfW, halfH);
      case Quadrant.q4:
        return Rect.fromLTWH(halfW, halfH, halfW, halfH);
    }
  }

  Rect _scaleRect(Rect r, double scale) {
    final c = r.center;
    final w = r.width * scale;
    final h = r.height * scale;
    return Rect.fromCenter(center: c, width: w, height: h);
  }

  // Snap rect coordinates to pixel grid to reduce hairline gaps.
  Rect _snapRect(Rect r) {
    double snap(double v) =>
        (v + 0.5).floorToDouble() + 0.0; // prefer whole-pixel alignment
    final l = snap(r.left);
    final t = snap(r.top);
    final rr = snap(r.right);
    final bb = snap(r.bottom);
    final w = (rr - l).clamp(0.0, double.infinity);
    final h = (bb - t).clamp(0.0, double.infinity);
    return Rect.fromLTWH(l, t, w, h);
  }

  /// Get or create a cached rounded rectangle path for the given rect.
  ///
  /// Memoizes paths by (taskId + rect hash) to avoid redundant path creation
  /// when layout is stable. This improves performance during interaction-only
  /// repaints (e.g., pointer movement, dragging state changes).
  ///
  /// Cache key invalidation: When rect changes, hashCode changes, creating a
  /// new cache entry. Old entries are orphaned but remain until GC.
  /// Cache is bounded implicitly by task count (max ~500 tasks × 2 states).
  // ignore: unused_element
  Path _getCachedPath(String taskId, Rect rect, double radius) {
    final key = '${taskId}_${rect.hashCode}_$radius#v$layoutVersion';
    return _pathCache.putIfAbsent(key, () {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    });
  }

  /// Draw corner indicators when zoomed into a specific quadrant.
  /// Shows L-shaped markers in corners to indicate quadrant boundaries.
  void _drawQuadrantCornerIndicators(
      Canvas canvas, Size size, Quadrant zoomedQuadrant) {
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = outlineColor.withValues(alpha: 0.25);

    const cornerLength = 20.0;
    const margin = 16.0;

    // Determine which corners to draw based on quadrant
    // Q1 (top-left): draw bottom-right corner
    // Q2 (top-right): draw bottom-left corner
    // Q3 (bottom-left): draw top-right corner
    // Q4 (bottom-right): draw top-left corner

    switch (zoomedQuadrant) {
      case Quadrant.q1:
        // Bottom-right corner (connects to Q2, Q3, Q4)
        final brX = size.width - margin;
        final brY = size.height - margin;
        canvas.drawLine(
          Offset(brX - cornerLength, brY),
          Offset(brX, brY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(brX, brY - cornerLength),
          Offset(brX, brY),
          cornerPaint,
        );
        break;

      case Quadrant.q2:
        // Bottom-left corner (connects to Q1, Q3, Q4)
        final blX = margin;
        final blY = size.height - margin;
        canvas.drawLine(
          Offset(blX, blY),
          Offset(blX + cornerLength, blY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(blX, blY - cornerLength),
          Offset(blX, blY),
          cornerPaint,
        );
        break;

      case Quadrant.q3:
        // Top-right corner (connects to Q1, Q2, Q4)
        final trX = size.width - margin;
        final trY = margin;
        canvas.drawLine(
          Offset(trX - cornerLength, trY),
          Offset(trX, trY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(trX, trY),
          Offset(trX, trY + cornerLength),
          cornerPaint,
        );
        break;

      case Quadrant.q4:
        // Top-left corner (connects to Q1, Q2, Q3)
        final tlX = margin;
        final tlY = margin;
        canvas.drawLine(
          Offset(tlX, tlY),
          Offset(tlX + cornerLength, tlY),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(tlX, tlY),
          Offset(tlX, tlY + cornerLength),
          cornerPaint,
        );
        break;
    }
  }

  TextPainter _textPainter(
    String text,
    Rect r,
    double size,
    FontWeight fw, {
    double alpha = 0.92,
    int maxLines = 2,
    Color? textColor,
  }) {
    final maxW = math.max(0.0, r.width - 16);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: fw,
          color: (textColor ?? Colors.white).withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    return tp;
  }
}

class _OutroState {
  _OutroState({
    required this.rect,
    required this.quadrant,
    required this.startedAt,
    required this.duration,
  });
  final Rect rect; // normalized 0..1
  final Quadrant? quadrant;
  final DateTime startedAt;
  final Duration duration;
  double progress(DateTime now) {
    final dt = now.difference(startedAt).inMilliseconds;
    final total = duration.inMilliseconds;
    if (total <= 0) return 1.0;
    final t = dt / total;
    return t.clamp(0.0, 1.0);
  }
}

// Top-level helper: reorder paint z-order so suggested ids in tie groups paint last per quadrant.
List<TreemapRect> reorderForTieBreak(
  List<TreemapRect> items,
  Set<String>? suggested,
) {
  if (suggested == null || suggested.isEmpty) return items;
  final byQ = <Quadrant, List<TreemapRect>>{
    for (final q in Quadrant.values) q: [],
  };
  for (final it in items) {
    byQ[it.task.quadrant]!.add(it);
  }
  final out = <TreemapRect>[];
  for (final q in Quadrant.values) {
    final list = byQ[q]!;
    if (list.isEmpty) continue;
    final areas = list.map((e) => e.rect01.width * e.rect01.height).toList();
    String sid = '';
    for (final s in suggested) {
      if (list.any((e) => e.task.id == s)) {
        sid = s;
        break;
      }
    }
    if (sid.isEmpty) {
      out.addAll(list);
      continue;
    }
    final idx = list.indexWhere((e) => e.task.id == sid);
    if (idx < 0) {
      out.addAll(list);
      continue;
    }
    final aS = areas[idx];
    final hasTie = areas.asMap().entries.any(
          (e) => e.key != idx && aS > 0 && ((e.value - aS).abs() / aS) <= 0.05,
        );
    if (!hasTie) {
      out.addAll(list);
      continue;
    }
    final reordered = [...list]..removeAt(idx);
    reordered.add(list[idx]);
    out.addAll(reordered);
  }
  return out;
}

// Group tiles into horizontal/vertical shelves by clustering similar edges.
List<Rect> _clusterShelves(List<Rect> rects) {
  if (rects.isEmpty) return const [];
  const eps = 0.75; // pixels tolerance
  final used = List<bool>.filled(rects.length, false);
  final shelves = <Rect>[];
  for (var i = 0; i < rects.length; i++) {
    if (used[i]) continue;
    final base = rects[i];
    // Try horizontal grouping by similar top/bottom
    final group = <Rect>[base];
    used[i] = true;
    for (var j = i + 1; j < rects.length; j++) {
      if (used[j]) continue;
      final rj = rects[j];
      final sameRow = ((rj.top - base.top).abs() < eps &&
              (rj.height - base.height).abs() < eps) ||
          ((rj.bottom - base.bottom).abs() < eps &&
              (rj.height - base.height).abs() < eps);
      final sameCol = ((rj.left - base.left).abs() < eps &&
              (rj.width - base.width).abs() < eps) ||
          ((rj.right - base.right).abs() < eps &&
              (rj.width - base.width).abs() < eps);
      if (sameRow || sameCol) {
        group.add(rj);
        used[j] = true;
      }
    }
    Rect union = group.first;
    for (final g in group.skip(1)) {
      union = union.expandToInclude(g);
    }
    shelves.add(union);
  }
  return shelves;
}
