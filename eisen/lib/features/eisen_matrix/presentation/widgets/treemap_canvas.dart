import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/responsive/app_breakpoints.dart';
import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/category_colors.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/_last_moved_highlight_overlay.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_painter.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_tile_tooltip.dart';
import 'package:flutter/material.dart';
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
    this.warningTaskIds = const <String>{},
    this.minTileSizePx = 44.0, // Default fallback
    this.categoryColorService, // Optional, falls back to default palette
    this.colorByCategory = false,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
    this.quadrantLabelStyle = QuadrantLabelStyle.professional,
    this.onLowConfidenceLongPress,
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
  final Set<String> warningTaskIds;
  // Minimum tile size for stacking threshold (desktop: 30-44, mobile: 40-44)
  final double minTileSizePx;
  // Category color service for consistent category colors (optional)
  final CategoryColorService? categoryColorService;
  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final QuadrantLabelStyle quadrantLabelStyle;

  /// Called when a low-confidence task is long-pressed. Opens QuickReclassifySheet.
  final void Function(Task task)? onLowConfidenceLongPress;

  @override
  State<TreemapCanvas> createState() => _TreemapCanvasState();
}

class _TreemapCanvasState extends State<TreemapCanvas> with TickerProviderStateMixin {
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
  final Map<String, OutroState> _pendingOutros = {};
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

  // Desktop hover tooltip state
  String? _hoveredTaskId;
  Offset? _hoverPosition;

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
            _pendingOutros[id] = OutroState(
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

        // Check if we're on large layouts (for hover tooltip).
        final isDesktop = deviceClassOf(constraints.maxWidth).isLarge;

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
        final double minAreaPx = (widget.minTileSizePx * widget.minTileSizePx) * (widget.compact ? 0.7 : 1.0);
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
            if (r.width < widget.minTileSizePx || r.height < widget.minTileSizePx || r.width * r.height < minAreaPx) {
              tinyByQ[tr.task.quadrant]!.add(tr);
            }
          }
        }
        if (widget.onEditTask != null || widget.onMarkDone != null) {
          // Adjust button visibility threshold by density
          final double minAreaForButtons = LayoutConstants.minAreaForButtons * (widget.compact ? 0.85 : 1.0);
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
            if (r.width >= widget.minTileSizePx && r.height >= widget.minTileSizePx) {
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
          Rect quadRect(Quadrant q) {
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
            final qRect = quadRect(q);
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
                // Outer MouseRegion for hover detection (desktop only)
                onHover: isDesktop
                    ? (event) {
                        final hoveredId = _hitTest(event.localPosition, size);
                        if (hoveredId != _hoveredTaskId) {
                          setState(() {
                            _hoveredTaskId = hoveredId;
                            _hoverPosition = event.localPosition;
                          });
                        }
                      }
                    : null,
                onExit: isDesktop
                    ? (_) {
                        setState(() {
                          _hoveredTaskId = null;
                          _hoverPosition = null;
                        });
                      }
                    : null,
                child: MouseRegion(
                  cursor: _draggingId != null ? SystemMouseCursors.grabbing : SystemMouseCursors.basic,
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
                      if (t != null &&
                          widget.showConfidenceIndicators &&
                          widget.onLowConfidenceLongPress != null &&
                          t.classificationConfidence == ConfidenceLevel.low) {
                        HapticFeedback.mediumImpact();
                        widget.onLowConfidenceLongPress!(t);
                        return;
                      }
                      final msg = t == null ? 'Tarea' : '${t.title} • P${t.priority} • ${t.minutes}m';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    onSecondaryTapDown: (d) {
                      final id = _hitTest(d.localPosition, size);
                      if (id == null) return;
                      final idx = widget.tasks.indexWhere((e) => e.id == id);
                      final t = idx == -1 ? null : widget.tasks[idx];
                      if (t != null &&
                          widget.showConfidenceIndicators &&
                          widget.onLowConfidenceLongPress != null &&
                          t.classificationConfidence == ConfidenceLevel.low) {
                        widget.onLowConfidenceLongPress!(t);
                        return;
                      }
                      widget.onTap?.call(id);
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
                      if (widget.inlineEditId == null && _draggingId != null && widget.zoom == null) {
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
                            painter: TreemapPainter(
                              widget.layout,
                              draggingId: _draggingId,
                              pointer: _lastPos,
                              hoverQuadrant: widget.zoom == null ? _hoverQuadrant : null,
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
                              warningTaskIds: widget.warningTaskIds,
                              categoryColorService: widget.categoryColorService,
                              colorByCategory: widget.colorByCategory,
                              showConfidenceIndicators: widget.showConfidenceIndicators,
                              showAutoTags: widget.showAutoTags,
                              quadrantLabelStyle: widget.quadrantLabelStyle,
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
                              duration: const Duration(milliseconds: 180),
                              child: ColoredBox(
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ), // Close MouseRegion (cursor)
            ), // Close MouseRegion (hover detection)
            // Desktop hover tooltip
            if (isDesktop &&
                _hoveredTaskId != null &&
                _hoverPosition != null &&
                _draggingId == null) // Don't show tooltip while dragging
              Builder(
                builder: (context) {
                  final task = widget.tasks.firstWhere(
                    (t) => t.id == _hoveredTaskId,
                    orElse: () => widget.tasks.first,
                  );
                  if (task.id != _hoveredTaskId) {
                    return const SizedBox.shrink();
                  }
                  return TreemapTileTooltip(
                    task: task,
                    position: _hoverPosition!,
                    screenSize: size,
                    categoryColorService: widget.categoryColorService,
                    showConfidenceIndicators: widget.showConfidenceIndicators,
                    showAutoTags: widget.showAutoTags,
                  );
                },
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
                    right = size.width / 2 + m; // anchor to Q1 right edge minus margin
                    bottom = size.height / 2 + m; // anchor to Q1 bottom edge minus margin
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
                            final fillAlpha = widget.minimal ? 0.25 : 0.18;
                            final borderColor = widget.minimal
                                ? Colors.black.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.18);
                            // Use dark gray text in minimal mode for better visibility on light surfaces
                            final textColor = widget.minimal ? const Color(0xFF424242) : Colors.white;
                            return Container(
                              width: widget.minTileSizePx,
                              height: widget.minTileSizePx,
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
      if (r.width < widget.minTileSizePx || r.height < widget.minTileSizePx) {
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
                      onPressed: widget.onEditTask == null ? null : () => widget.onEditTask!(t.id),
                    ),
                    PopupMenuButton<Quadrant>(
                      tooltip: 'Mover a',
                      onSelected: (dest) => widget.onDropToQuadrant?.call(t.id, dest),
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
            color: minimal ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: minimal ? Colors.black26 : Colors.white.withValues(alpha: 0.25),
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

/// Desktop hover tooltip widget - shows full task details on mouse hover
/// Only displayed on desktop platforms with pointer input
