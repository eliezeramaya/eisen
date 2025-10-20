import 'package:flutter/material.dart';
import '../../domain/models.dart';

class Sparkline extends StatelessWidget {
  final List<TrendPoint>? trend;
  const Sparkline({super.key, this.trend});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CustomPaint(painter: _SparkPainter(trend ?? const [])),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<TrendPoint> trend;
  _SparkPainter(this.trend);
  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;
    final maxV = trend.map((e) => e.focusMinutes).fold<int>(1, (a, b) => b > a ? b : a).toDouble();
    final path = Path();
    for (int i = 0; i < trend.length; i++) {
      final x = size.width * (i / (trend.length - 1).clamp(1, 1));
      final y = size.height * (1 - (trend[i].focusMinutes / maxV));
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.9);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.18);
    // Fill area under curve
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.trend != trend;
}

