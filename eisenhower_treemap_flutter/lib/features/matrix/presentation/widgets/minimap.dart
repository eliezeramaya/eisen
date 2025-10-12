import 'package:flutter/material.dart';
import '../../domain/entities.dart';

class Minimap extends StatelessWidget {
  final Quadrant? zoom;
  const Minimap({super.key, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        size: const Size(80, 80),
        painter: _MinimapPainter(zoom),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final Quadrant? zoom;
  _MinimapPainter(this.zoom);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white70;
    final cell = Rect.fromLTWH(0, 0, size.width / 2, size.height / 2);
    canvas.drawRect(cell, p);
    canvas.drawRect(cell.shift(Offset(size.width / 2, 0)), p);
    canvas.drawRect(cell.shift(Offset(0, size.height / 2)), p);
    canvas.drawRect(cell.shift(Offset(size.width / 2, size.height / 2)), p);

    if (zoom != null) {
      final fill = Paint()..color = Colors.white24;
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
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => oldDelegate.zoom != zoom;
}
