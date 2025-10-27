import 'package:flutter/material.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/l10n/app_localizations.dart';

class Minimap extends StatelessWidget {
  final Quadrant? zoom;
  final void Function(Quadrant q)? onSelectQuadrant;
  final VoidCallback? onFullView;
  final bool minimal;
  final List<Task>? tasks; // optional: heat density by weights
  const Minimap({super.key, required this.zoom, this.onSelectQuadrant, this.onFullView, this.minimal = false, this.tasks});

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final doLabel = l10n.minimapDo;
  final decideLabel = l10n.minimapDecide;
  final delegateLabel = l10n.minimapDelegate;
  final deleteLabel = l10n.minimapDelete;
    return GestureDetector(
      onTapDown: (details) {
        final local = details.localPosition;
        final size = const Size(80, 80);
        final halfW = size.width / 2;
        final halfH = size.height / 2;
        // Center hit area (full view)
        final center = Offset(halfW, halfH);
        if ((local - center).distance <= 10) {
          onFullView?.call();
          return;
        }
        // Quadrant hit tests
        if (onSelectQuadrant != null) {
          final left = local.dx < halfW;
          final top = local.dy < halfH;
          final q = left && top
              ? Quadrant.q1
              : (!left && top)
                  ? Quadrant.q2
                  : (left && !top)
                      ? Quadrant.q3
                      : Quadrant.q4;
          onSelectQuadrant!(q);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: minimal ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: minimal ? Border.all(color: Colors.black54, width: 1) : null,
        ),
        child: CustomPaint(
          size: const Size(80, 80),
          painter: _MinimapPainter(zoom, doLabel, decideLabel, delegateLabel, deleteLabel, minimal: minimal, tasks: tasks),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final Quadrant? zoom;
  final String doLabel;
  final String decideLabel;
  final String delegateLabel;
  final String deleteLabel;
  final bool minimal;
  final List<Task>? tasks;
  _MinimapPainter(this.zoom, this.doLabel, this.decideLabel, this.delegateLabel, this.deleteLabel, {this.minimal = false, this.tasks});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = minimal ? Colors.black87 : Colors.white70;
    final cell = Rect.fromLTWH(0, 0, size.width / 2, size.height / 2);

    // Optional heat density by total weight per quadrant
    if (tasks != null && tasks!.isNotEmpty) {
      final sums = <Quadrant, double>{for (final q in Quadrant.values) q: 0.0};
      for (final t in tasks!) {
        sums[t.quadrant] = (sums[t.quadrant] ?? 0) + weight(t);
      }
      final maxV = sums.values.fold<double>(0, (a, b) => a > b ? a : b);
      Color heat(double v) {
        final k = (maxV <= 0) ? 0.0 : (v / maxV).clamp(0.0, 1.0);
        final base = minimal ? Colors.black : Colors.white;
        // Use subtle alpha ramp [0.06..0.22]
        final alpha = 0.06 + 0.16 * k;
        return base.withValues(alpha: alpha);
      }
      void fillQ(Quadrant q, Rect r) {
        final paint = Paint()..color = heat(sums[q] ?? 0);
        canvas.drawRect(r, paint);
      }
      fillQ(Quadrant.q1, cell);
      fillQ(Quadrant.q2, cell.shift(Offset(size.width / 2, 0)));
      fillQ(Quadrant.q3, cell.shift(Offset(0, size.height / 2)));
      fillQ(Quadrant.q4, cell.shift(Offset(size.width / 2, size.height / 2)));
    }
    canvas.drawRect(cell, p);
    canvas.drawRect(cell.shift(Offset(size.width / 2, 0)), p);
    canvas.drawRect(cell.shift(Offset(0, size.height / 2)), p);
    canvas.drawRect(cell.shift(Offset(size.width / 2, size.height / 2)), p);

  // Prepare label painters helper
    final tp = (String text) => TextPainter(
      text: TextSpan(style: TextStyle(color: minimal ? const Color(0xFF424242) : Colors.white, fontSize: 10, fontWeight: FontWeight.w600), text: text),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: cell.width - 6);
    void drawLabel(Rect r, String text) {
      final t = tp(text);
      final offset = Offset(r.left + 3, r.top + 2);
      t.paint(canvas, offset);
    }

    if (zoom != null) {
      final fill = Paint()..color = minimal ? Colors.black12 : Colors.white24;
      Rect zr;
      switch (zoom!) {
        case Quadrant.q1:
          zr = cell;
          break;
        case Quadrant.q2:
          zr = cell.shift(Offset(size.width / 2, 0));
          break;
        case Quadrant.q3:
          zr = cell.shift(Offset(0, size.height / 2));
          break;
        case Quadrant.q4:
          zr = cell.shift(Offset(size.width / 2, size.height / 2));
          break;
      }
      canvas.drawRect(zr, fill);
    }

    // Center full-view dot
    final center = Offset(size.width / 2, size.height / 2);
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = minimal ? Colors.black54 : Colors.white70;
    canvas.drawCircle(center, 4, centerPaint);

  // Labels: Q1/Q2/Q3/Q4 (drawn above highlight)
  drawLabel(cell, doLabel);
  drawLabel(cell.shift(Offset(size.width / 2, 0)), decideLabel);
  drawLabel(cell.shift(Offset(0, size.height / 2)), delegateLabel);
  drawLabel(cell.shift(Offset(size.width / 2, size.height / 2)), deleteLabel);
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => oldDelegate.zoom != zoom;
}
