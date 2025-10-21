import 'dart:ui' as ui show lerpDouble;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:eisen/core/theme/animation_tokens.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:eisen/core/services/telemetry.dart';
import 'package:eisen/features/eisen_matrix/presentation/widgets/treemap_debug.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart' show debugTreemap;
import 'package:eisen/core/constants/layout_constants.dart';

class TreemapCanvas extends StatefulWidget {
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
  });

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
  final _inlineController = TextEditingController();
  final _inlineFocus = FocusNode();
  late final AnimationController _pulse;
  double _pulseT = 0.0;
  Quadrant? _pulseQuadrant;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: AnimTokens.layout)
      ..addListener(() {
        setState(() => _t = _anim.value);
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
  }

  @override
  void didUpdateWidget(covariant TreemapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.layout, widget.layout)) {
      final newRects = _rectMap(widget.layout);
      if (_nextRects01.isEmpty) {
        _nextRects01 = newRects;
        _t = 1.0;
      } else {
        _prevRects01 = _nextRects01;
        _nextRects01 = newRects;
        // Restart animation
        _anim.stop();
        _anim.forward(from: 0);
      }
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // Provide a safe fallback for theme tokens so tests that don't install the app theme don't crash
        final glassTokens = Theme.of(context).extension<GlassTokens>() ?? const GlassTokens(
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
        final hasStackTiles = widget.layout.any((e) => e.stackChildren.isNotEmpty);
        // Compute tiny tiles per quadrant only if no integrated stacks present
  final minAreaPx = LayoutConstants.minTileAreaPx;
        final tinyByQ = <Quadrant, List<TreemapRect>>{
          Quadrant.q1: [], Quadrant.q2: [], Quadrant.q3: [], Quadrant.q4: []
        };
        if (!hasStackTiles) {
          for (final tr in widget.layout) {
            final r = _px(tr.rect01, size);
            if (r.width * r.height < minAreaPx) {
              tinyByQ[tr.task.quadrant]!.add(tr);
            }
          }
        }
        if (widget.onEditTask != null || widget.onMarkDone != null) {
          for (final tr in widget.layout) {
            final r = _px(tr.rect01, size);
            // Show edit button only for reasonably large tiles
            if (r.width * r.height < LayoutConstants.minAreaForButtons) continue;
            const btn = 28.0;
            if (widget.onMarkDone != null) {
              overlay.add(Positioned(
                left: r.left + 6,
                top: r.top + 6,
                width: btn,
                height: btn,
                child: _CheckDot(
                  onPressed: () => widget.onMarkDone?.call(tr.task.id),
                  minimal: widget.minimal,
                ),
              ));
            }
            overlay.add(Positioned(
              left: r.right - btn - 6,
              top: r.top + 6,
              width: btn,
              height: btn,
              child: _EditDot(
                onPressed: () => widget.onEditTask?.call(tr.task.id),
              ),
            ));
          }
        }

        return Stack(
          children: [
            Positioned.fill(
              child: MouseRegion(
                cursor: _draggingId != null ? SystemMouseCursors.grabbing : SystemMouseCursors.basic,
                child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final id = _hitTest(d.localPosition, size);
                  if (id != null) {
                    final idx = widget.layout.indexWhere((e) => e.task.id == id);
                    final tr = idx == -1 ? null : widget.layout[idx];
                    if (tr != null && tr.stackChildren.isNotEmpty) {
                      // Open stack sheet for this quadrant
                      Telemetry.stackOpen(tr.task.quadrant.name, tr.stackChildren.length);
                      _openStackSheet(context, tr.task.quadrant, tr.stackChildren);
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
                  final msg = t == null ? 'Tarea' : '${t.title} • P${t.priority} • ${t.minutes}m';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)),
                  );
                },
                onPanStart: (d) {
                  if (widget.inlineEditId != null) return; // disable drag while editing
                  setState(() {
                    _draggingId = _hitTest(d.localPosition, size);
                    _lastPos = d.localPosition;
                    _hoverQuadrant = _quadrantAt(_lastPos!, size);
                  });
                  if (_draggingId != null) Telemetry.tileDragStart(_draggingId!);
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
                child: CustomPaint(
                  painter: _TreemapPainter(
                    widget.layout,
                    draggingId: _draggingId,
                    pointer: _lastPos,
                    hoverQuadrant: widget.zoom == null ? _hoverQuadrant : null,
                    presentQuadrant: widget.presentQuadrant,
                    prevRects01: _prevRects01,
                    nextRects01: _nextRects01,
                    t: _t,
                    tokens: glassTokens,
                    minimal: widget.minimal,
                    pulseQuadrant: _pulseQuadrant,
                    pulseT: _pulseT,
                    suggested: widget.suggestedIds,
                  ),
                  isComplex: true,
                  willChange: true,
                  child: const SizedBox.expand(),
                ),
                ),
              ),
            ),
            // Stack overlays per quadrant
            if (!hasStackTiles) ...Quadrant.values.map((q) {
              final count = tinyByQ[q]!.length;
              if (count == 0) return const SizedBox.shrink();
              final pos = _stackOverlayPosition(q, size);
              return Positioned(
                key: ValueKey('stack_${q.name}'),
                left: pos.dx,
                top: pos.dy,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Telemetry.stackOpen(q.name, count);
                      _openStackSheet(context, q, tinyByQ[q]!.map((e) => e.task).toList());
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.minimal ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                      ),
                      child: Text('+${count}', style: TextStyle(
                        color: widget.minimal ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ),
                ),
              );
            }),
            if (widget.inlineEditId != null)
              _buildInlineEditor(context, size),
            ...overlay,
          ],
        );
      },
    );
  }

  String? _hitTest(Offset pos, Size size) {
  const minAreaPx = LayoutConstants.minTileAreaPx;
    for (final tr in widget.layout) {
      final r = _px(tr.rect01, size);
      if (r.width * r.height < minAreaPx) continue; // not interactive; represented by stack tile
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

  Rect _px(Rect r01, Size size) => Rect.fromLTWH(r01.left * size.width, r01.top * size.height, r01.width * size.width, r01.height * size.height);

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

  Offset _stackOverlayPosition(Quadrant q, Size size) {
    // Position near top-left of each quadrant, with margin
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    const m = 8.0;
    switch (q) {
      case Quadrant.q1:
        return const Offset(8, 8);
      case Quadrant.q2:
        return Offset(halfW + m, 8);
      case Quadrant.q3:
        return Offset(8, halfH + m);
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
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('P${t.priority} • ${t.minutes}m${t.due != null ? ' • due' : ''}'),
                trailing: Wrap(spacing: 8, children: [
                  IconButton(
                    tooltip: '+15m',
                    icon: const Icon(Icons.add_alarm),
                    onPressed: widget.onEditTask == null ? null : () => widget.onEditTask!(t.id),
                  ),
                  PopupMenuButton<Quadrant>(
                    tooltip: 'Mover a',
                    onSelected: (dest) => widget.onDropToQuadrant?.call(t.id, dest),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: Quadrant.q1, child: Text('Q1')),
                      const PopupMenuItem(value: Quadrant.q2, child: Text('Q2')),
                      const PopupMenuItem(value: Quadrant.q3, child: Text('Q3')),
                      const PopupMenuItem(value: Quadrant.q4, child: Text('Q4')),
                    ],
                    child: const Icon(Icons.open_in_full),
                  ),
                  IconButton(
                    tooltip: 'Marcar done',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => widget.onEditTask?.call(t.id),
                  ),
                ]),
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
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
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
  final VoidCallback onPressed;
  const _EditDot({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          splashRadius: 16,
          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
          tooltip: 'Edit task',
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  final VoidCallback onPressed;
  final bool minimal;
  const _CheckDot({required this.onPressed, required this.minimal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: minimal ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: minimal ? Colors.black26 : Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          splashRadius: 16,
          icon: Icon(Icons.check, size: 16, color: minimal ? Colors.black : Colors.white),
          tooltip: 'Completar',
        ),
      ),
    );
  }
}

class _TreemapPainter extends CustomPainter {
  final List<TreemapRect> layout;
  final String? draggingId;
  final Offset? pointer;
  final Quadrant? hoverQuadrant;
  final Quadrant? presentQuadrant;
  final Map<String, Rect> prevRects01;
  final Map<String, Rect> nextRects01;
  final double t; // 0..1
  final GlassTokens tokens;
  final bool minimal;
  final Quadrant? pulseQuadrant;
  final double pulseT; // 0..1
  final Set<String>? suggested;
  _TreemapPainter(
    this.layout, {
    this.draggingId,
    this.pointer,
    this.hoverQuadrant,
    this.presentQuadrant,
    required this.prevRects01,
    required this.nextRects01,
    required this.t,
    required this.tokens,
    required this.minimal,
    this.pulseQuadrant,
    this.pulseT = 0.0,
    this.suggested,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    const double gap = 4.0; // space between tiles to avoid clipped corners

    // Always draw subtle quadrant grid (center cross) so the matrix is visible even with no tiles
    final centerLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = minimal ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08);
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    // Vertical center line
    canvas.drawLine(Offset(halfW, 0), Offset(halfW, size.height), centerLine);
    // Horizontal center line
    canvas.drawLine(Offset(0, halfH), Offset(size.width, halfH), centerLine);

    // Debug: quadrant bounds in blue (disabled in minimal to keep visuals stable)
    if (debugTreemap && !minimal) {
      TreemapDebugOverlay.drawQuadrantBounds(canvas, Rect.fromLTWH(0, 0, halfW, halfH));
      TreemapDebugOverlay.drawQuadrantBounds(canvas, Rect.fromLTWH(halfW, 0, halfW, halfH));
      TreemapDebugOverlay.drawQuadrantBounds(canvas, Rect.fromLTWH(0, halfH, halfW, halfH));
      TreemapDebugOverlay.drawQuadrantBounds(canvas, Rect.fromLTWH(halfW, halfH, halfW, halfH));
    }

    // Present quadrant glow
    if (presentQuadrant != null && hoverQuadrant == null) {
      final qRect = _quadrantRect(presentQuadrant!, size);
      final grad = RadialGradient(colors: [Colors.white.withValues(alpha: minimal ? 0.12 : 0.06), Colors.transparent]);
      final paintGlow = Paint()..shader = grad.createShader(qRect);
      canvas.drawRect(qRect, paintGlow);
    }

    // Highlight hovered quadrant as a subtle overlay (takes precedence)
    if (hoverQuadrant != null) {
      final qRect = _quadrantRect(hoverQuadrant!, size);
      final qColor = minimal ? Colors.black : _byQuadrant(hoverQuadrant!);
      final overlay = Paint()
        ..style = PaintingStyle.fill
        ..color = minimal ? Colors.black.withValues(alpha: 0.06) : qColor.withValues(alpha: 0.08);
      canvas.drawRect(qRect, overlay);

      // Soft border glow
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..color = minimal ? Colors.black.withValues(alpha: 0.25) : qColor.withValues(alpha: 0.25)
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
      final byQ = <Quadrant, List<Rect>>{for (final q in Quadrant.values) q: []};
      for (final tr in layout) {
        final rr = Rect.fromLTWH(tr.rect01.left * size.width, tr.rect01.top * size.height, tr.rect01.width * size.width, tr.rect01.height * size.height);
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
      final r0 = Rect.fromLTWH(r01.left * size.width, r01.top * size.height, r01.width * size.width, r01.height * size.height);
      final r = _snapRect(r0);
      final color = minimal ? Colors.black : _byQuadrant(tr.task.quadrant);

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
          shift += len > 0 ? Offset(v.dx / len * maxShift, v.dy / len * maxShift) : Offset.zero;
        }
        // Magnetism: bias towards center of hovered quadrant
        if (hoverQuadrant != null) {
          final qCenter = _quadrantRect(hoverQuadrant!, size).center;
          final mv = qCenter - scaled.center;
          final mlen = mv.distance;
          final mMax = 8.0;
          final bias = 0.12; // fraction towards center
          final mshift = mlen > 0 ? Offset(mv.dx / mlen * mMax * bias, mv.dy / mlen * mMax * bias) : Offset.zero;
          shift += mshift;
        }
        drawRect = scaled.shift(shift);
        // No shadow in minimal mode
        if (!minimal) {
          canvas.drawShadow(
              Path()..addRRect(RRect.fromRectAndRadius(drawRect, const Radius.circular(12))),
              color.withValues(alpha: 0.45),
              14,
              false);
        }
      } else {
        drawRect = r;
        // No shadow in minimal mode
        if (!minimal) {
          canvas.drawShadow(
              Path()..addRRect(RRect.fromRectAndRadius(drawRect, const Radius.circular(12))),
              color.withValues(alpha: 0.3),
              8,
              false);
        }
      }
      // Deflate to create a gutter around each tile so rounded borders are visible
      // Clamp gutter so we don't invert tiny rects
      final safeGap = math.min(gap, math.max(0.0, math.min(drawRect.width, drawRect.height) * 0.5 - 0.5));
      drawRect = drawRect.deflate(safeGap);
      // Fill + Border (guarded for debug vs. normal styling)
      final rr = RRect.fromRectAndRadius(drawRect, const Radius.circular(12));
      // Use conservative alphas for production; reserve higher alpha for ephemeral debug builds
      final fillAlpha = (debugTreemap && !minimal) ? 0.28 : (minimal ? 0.22 : 0.14);
      paint
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: fillAlpha);
      canvas.drawRRect(rr, paint);
      paint
        ..style = PaintingStyle.stroke
        ..color = minimal ? Colors.black.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = (debugTreemap && !minimal) ? 2.0 : 1.0;
      canvas.drawRRect(rr, paint);


      if (isDragging) {
        // Extra highlight ring when dragging
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 2.0;
        canvas.drawRRect(rr.deflate(1), ring);
      }
      
      // If this is a stack tile, render a centered +N label and skip details
      if (tr.stackChildren.isNotEmpty) {
        final label = '+${tr.stackChildren.length}';
        final tp = _textPainter(label, drawRect, 14, FontWeight.w700, textColor: minimal ? Colors.black : Colors.white);
        tp.paint(canvas, Offset(drawRect.center.dx - tp.width / 2, drawRect.center.dy - tp.height / 2));
        continue;
      }

      // Title + metadata
      final area = drawRect.width * drawRect.height;
      final availableHeight = drawRect.height - 12; // padding top+bottom
      double currentY = drawRect.top + 6;

      // Paint title: keep sizes conservative; only allow multi-line in explicit debug mode
      final titleSize = debugTreemap ? 15.0 : 13.0;
      final canShowTitle = debugTreemap || availableHeight > 18.0;
      if (canShowTitle) {
        final tp = _textPainter(tr.task.title, drawRect, titleSize, FontWeight.w700, textColor: minimal ? Colors.black : Colors.white, maxLines: debugTreemap ? 3 : 1);
        tp.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp.height + 2;
      }
      
      // Priority and time (if medium+ size)
      if (area > 12000 && currentY + 14 < drawRect.bottom - 6 && !debugTreemap) {
        final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
        final tp2 = _textPainter(meta, drawRect, 12, FontWeight.w500, alpha: minimal ? 0.95 : 0.9, textColor: minimal ? Colors.black : Colors.white);
        tp2.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp2.height + 2;
      }
      
      // Notes preview (if large size and has notes)
      if (area > 26000 && tr.task.notes != null && tr.task.notes!.isNotEmpty && currentY + 14 < drawRect.bottom - 6 && !debugTreemap) {
        final notesPreview = tr.task.notes!.length > 50 
            ? '${tr.task.notes!.substring(0, 50)}...' 
            : tr.task.notes!;
        final tp3 = _textPainter(notesPreview, drawRect, 12, FontWeight.w400, alpha: minimal ? 0.9 : 0.85, maxLines: 2, textColor: minimal ? Colors.black : Colors.white);
        tp3.paint(canvas, Offset(drawRect.left + 8, currentY));
      }

      // Quadrant color indicator
      paint
        ..style = PaintingStyle.fill
        ..color = minimal ? Colors.black.withValues(alpha: 0.5) : color.withValues(alpha: 0.12);
      final ind = Rect.fromLTWH(drawRect.right - 10, drawRect.top + 4, 6, 6);
      canvas.drawRRect(RRect.fromRectAndRadius(ind, const Radius.circular(2)), paint);

      // Suggested by bandit badge (small star)
      if (suggested?.contains(tr.task.id) == true) {
        final star = _textPainter('★', drawRect, 12, FontWeight.w700, alpha: minimal ? 0.95 : 0.9, textColor: minimal ? Colors.black : Colors.white);
        star.paint(canvas, Offset(drawRect.left + 6, drawRect.top + 4));
      }

      // Debug labels for each tile
      if (debugTreemap && !minimal) {
        final area = (drawRect.width * drawRect.height) / (size.width * size.height);
        final ratio = drawRect.width == 0 || drawRect.height == 0
            ? 0.0
            : (drawRect.width / drawRect.height).abs();
        final rr = ratio < 1 ? 1 / (ratio == 0.0 ? 1.0 : ratio) : ratio;
        TreemapDebugOverlay.labelTile(canvas, drawRect, tr.task.id, area, rr);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.draggingId != draggingId ||
      oldDelegate.pointer != pointer ||
      oldDelegate.hoverQuadrant != hoverQuadrant ||
      oldDelegate.t != t ||
      oldDelegate.suggested != suggested ||
      oldDelegate.pulseQuadrant != pulseQuadrant ||
      oldDelegate.pulseT != pulseT ||
      oldDelegate.prevRects01 != prevRects01 ||
      oldDelegate.nextRects01 != nextRects01;

  @override
  bool shouldRebuildSemantics(covariant _TreemapPainter oldDelegate) => oldDelegate.layout != layout;

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
        final nodes = <CustomPainterSemantics>[];
        for (final tr in layout) {
          final r = Rect.fromLTWH(tr.rect01.left * size.width, tr.rect01.top * size.height, tr.rect01.width * size.width, tr.rect01.height * size.height);
          final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
          final label = tr.stackChildren.isNotEmpty
              ? 'Grupo ${tr.task.quadrant.name.toUpperCase()} (+${tr.stackChildren.length})'
              : '${tr.task.title}, $meta, ${tr.task.quadrant.name.toUpperCase()}${(suggested?.contains(tr.task.id) ?? false) ? ', sugerida' : ''}';
          nodes.add(CustomPainterSemantics(
            rect: r,
            properties: SemanticsProperties(
              label: label,
              button: true,
              textDirection: TextDirection.ltr,
            ),
          ));
        }
        return nodes;
      };

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
    double snap(double v) => (v + 0.5).floorToDouble() + 0.0; // prefer whole-pixel alignment
    final l = snap(r.left);
    final t = snap(r.top);
    final rr = snap(r.right);
    final bb = snap(r.bottom);
    final w = (rr - l).clamp(0.0, double.infinity);
    final h = (bb - t).clamp(0.0, double.infinity);
    return Rect.fromLTWH(l, t, w, h);
  }

  TextPainter _textPainter(String text, Rect r, double size, FontWeight fw, {double alpha = 0.92, int maxLines = 1, Color? textColor}) {
    final maxW = math.max(0.0, r.width - 16);
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: fw, color: (textColor ?? Colors.white).withValues(alpha: alpha))),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxW);
    return tp;
  }

}

// Top-level helper: reorder paint z-order so suggested ids in tie groups paint last per quadrant.
List<TreemapRect> reorderForTieBreak(List<TreemapRect> items, Set<String>? suggested) {
  if (suggested == null || suggested.isEmpty) return items;
  final byQ = <Quadrant, List<TreemapRect>>{for (final q in Quadrant.values) q: []};
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
      if (list.any((e) => e.task.id == s)) { sid = s; break; }
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
    final hasTie = areas.asMap().entries.any((e) => e.key != idx && aS > 0 && ((e.value - aS).abs() / aS) <= 0.05);
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
      final sameRow = ( (rj.top - base.top).abs() < eps && (rj.height - base.height).abs() < eps ) ||
                      ( (rj.bottom - base.bottom).abs() < eps && (rj.height - base.height).abs() < eps );
      final sameCol = ( (rj.left - base.left).abs() < eps && (rj.width - base.width).abs() < eps ) ||
                      ( (rj.right - base.right).abs() < eps && (rj.width - base.width).abs() < eps );
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
