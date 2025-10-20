import 'package:flutter/material.dart';
import 'package:eisen/core/theme/app_theme.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';

class TreemapCanvas extends StatefulWidget {
  final List<Task> tasks;
  final List<TreemapRect> layout;
  final void Function(String? id)? onTap;
  final void Function(String id, Quadrant q)? onDropToQuadrant;
  final void Function(Quadrant q)? onDoubleTapQuadrant;
  final Quadrant? zoom;
  final void Function(String id)? onEditTask;
  final String? inlineEditId;
  final void Function(String id, String title)? onInlineSubmit;
  final void Function(String id)? onInlineCancel;
  final bool minimal;

  const TreemapCanvas({
    super.key,
    required this.tasks,
    required this.layout,
    this.onTap,
    this.onDropToQuadrant,
    this.onDoubleTapQuadrant,
    this.zoom,
    this.onEditTask,
    this.inlineEditId,
    this.onInlineSubmit,
    this.onInlineCancel,
    this.minimal = false,
  });

  @override
  State<TreemapCanvas> createState() => _TreemapCanvasState();
}

class _TreemapCanvasState extends State<TreemapCanvas> with SingleTickerProviderStateMixin {
  String? _draggingId;
  Offset? _lastPos;
  Quadrant? _hoverQuadrant;
  late final AnimationController _anim;
  double _t = 1.0;
  Map<String, Rect> _prevRects01 = {};
  Map<String, Rect> _nextRects01 = {};
  final _inlineController = TextEditingController();
  final _inlineFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        setState(() => _t = _anim.value);
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
        // Prefill with current title
        final t = widget.tasks.firstWhere((e) => e.id == widget.inlineEditId, orElse: () => widget.tasks.first);
        _inlineController.text = t.title;
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
    _inlineController.dispose();
    _inlineFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final overlay = <Widget>[];
        if (widget.onEditTask != null) {
          for (final tr in widget.layout) {
            final r = _px(tr.rect01, size);
            // Show edit button only for reasonably large tiles
            if (r.width * r.height < 12000) continue;
            const btn = 28.0;
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
                  widget.onTap?.call(id);
                },
                onDoubleTapDown: (d) {
                  final q = _quadrantAt(d.localPosition, size);
                  if (q != null) widget.onDoubleTapQuadrant?.call(q);
                },
                onPanStart: (d) {
                  if (widget.inlineEditId != null) return; // disable drag while editing
                  setState(() {
                    _draggingId = _hitTest(d.localPosition, size);
                    _lastPos = d.localPosition;
                    _hoverQuadrant = _quadrantAt(_lastPos!, size);
                  });
                },
                onPanEnd: (d) {
                  if (widget.inlineEditId == null && _draggingId != null && widget.zoom == null) {
                    final q = _quadrantAt(_lastPos ?? Offset.zero, size);
                    if (q != null) widget.onDropToQuadrant?.call(_draggingId!, q);
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
                    prevRects01: _prevRects01,
                    nextRects01: _nextRects01,
                    t: _t,
                    tokens: Theme.of(context).extension<GlassTokens>()!,
                    minimal: widget.minimal,
                  ),
                  isComplex: true,
                  willChange: true,
                  child: const SizedBox.expand(),
                ),
                ),
              ),
            ),
            if (widget.inlineEditId != null)
              _buildInlineEditor(context, size),
            ...overlay,
          ],
        );
      },
    );
  }

  String? _hitTest(Offset pos, Size size) {
    for (final tr in widget.layout) {
      final r = _px(tr.rect01, size);
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
    for (final tr in layout) {
      m[tr.task.id] = tr.rect01;
    }
    return m;
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

class _TreemapPainter extends CustomPainter {
  final List<TreemapRect> layout;
  final String? draggingId;
  final Offset? pointer;
  final Quadrant? hoverQuadrant;
  final Map<String, Rect> prevRects01;
  final Map<String, Rect> nextRects01;
  final double t; // 0..1
  final GlassTokens tokens;
  final bool minimal;
  _TreemapPainter(
    this.layout, {
    this.draggingId,
    this.pointer,
    this.hoverQuadrant,
    required this.prevRects01,
    required this.nextRects01,
    required this.t,
    required this.tokens,
    required this.minimal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    const double gap = 4.0; // space between tiles to avoid clipped corners

    // Highlight hovered quadrant as a subtle overlay
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

    final curveT = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    for (final tr in layout) {
      final id = tr.task.id;
      final r01From = prevRects01[id] ?? tr.rect01;
      final r01To = nextRects01[id] ?? tr.rect01;
      final r01 = Rect.lerp(r01From, r01To, curveT)!;
      final r = Rect.fromLTWH(r01.left * size.width, r01.top * size.height, r01.width * size.width, r01.height * size.height);
  final color = minimal ? Colors.black : _byQuadrant(tr.task.quadrant);

      // If dragging this tile, render it "lifted"
      final bool isDragging = tr.task.id == draggingId;
      Rect drawRect;
      if (isDragging) {
        // Scale around center and slightly offset towards pointer
        final scaled = _scaleRect(r, 1.04);
        if (pointer != null) {
          final v = pointer! - scaled.center;
          final len = v.distance;
          final maxShift = 6.0;
          final shift = len > 0 ? Offset(v.dx / len * maxShift, v.dy / len * maxShift) : Offset.zero;
          drawRect = scaled.shift(shift);
        } else {
          drawRect = scaled;
        }
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
      drawRect = drawRect.deflate(gap);
      // Fill
      final rr = RRect.fromRectAndRadius(drawRect, const Radius.circular(12));
      if (!minimal) {
        paint
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.06);
        canvas.drawRRect(rr, paint);
      } else {
        // Flat white background already applied behind; skip inner fill
      }
      // Border
      paint
        ..style = PaintingStyle.stroke
        ..color = minimal ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1;
      canvas.drawRRect(rr, paint);


      if (isDragging) {
        // Extra highlight ring when dragging
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 2.0;
        canvas.drawRRect(rr.deflate(1), ring);
      }
      
      // Adaptive text rendering based on tile size
      final area = drawRect.width * drawRect.height;
      final availableHeight = drawRect.height - 12; // padding top+bottom
      double currentY = drawRect.top + 6;
      
      // Title (always shown if space)
      if (availableHeight > 16) {
        final titleSize = area > 20000 ? 13.0 : 12.0;
        final tp = _textPainter(tr.task.title, drawRect, titleSize, FontWeight.w600, textColor: minimal ? Colors.black : Colors.white);
        tp.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp.height + 3;
      }
      
      // Priority and time (if medium+ size)
      if (area > 12000 && currentY + 14 < drawRect.bottom - 6) {
        final meta = 'P${tr.task.priority} • ${tr.task.minutes}m';
        final tp2 = _textPainter(meta, drawRect, 11, FontWeight.w400, alpha: 0.9, textColor: minimal ? Colors.black : Colors.white);
        tp2.paint(canvas, Offset(drawRect.left + 8, currentY));
        currentY += tp2.height + 3;
      }
      
      // Notes preview (if large size and has notes)
      if (area > 25000 && tr.task.notes != null && tr.task.notes!.isNotEmpty && currentY + 14 < drawRect.bottom - 6) {
        final notesPreview = tr.task.notes!.length > 50 
            ? '${tr.task.notes!.substring(0, 50)}...' 
            : tr.task.notes!;
        final tp3 = _textPainter(notesPreview, drawRect, 10, FontWeight.w300, alpha: 0.85, maxLines: 2, textColor: minimal ? Colors.black : Colors.white);
        tp3.paint(canvas, Offset(drawRect.left + 8, currentY));
      }

      // Quadrant color indicator
      paint
        ..style = PaintingStyle.fill
        ..color = minimal ? Colors.black.withValues(alpha: 0.5) : color.withValues(alpha: 0.12);
      final ind = Rect.fromLTWH(drawRect.right - 10, drawRect.top + 4, 6, 6);
      canvas.drawRRect(RRect.fromRectAndRadius(ind, const Radius.circular(2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.draggingId != draggingId ||
      oldDelegate.pointer != pointer ||
      oldDelegate.hoverQuadrant != hoverQuadrant ||
      oldDelegate.t != t ||
      oldDelegate.prevRects01 != prevRects01 ||
      oldDelegate.nextRects01 != nextRects01;

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

  TextPainter _textPainter(String text, Rect r, double size, FontWeight fw, {double alpha = 0.92, int maxLines = 1, Color? textColor}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: fw, color: (textColor ?? Colors.white).withValues(alpha: alpha))),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: r.width - 16);
    return tp;
  }
}
