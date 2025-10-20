import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eisen/features/stats/domain/models.dart';

/// Donut chart for Q1..Q4 without external deps.
class DonutBalance extends StatelessWidget {
  final BalanceBreakdown? balance;
  const DonutBalance({super.key, this.balance});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DonutPainter(balance),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final BalanceBreakdown? b;
  _DonutPainter(this.b);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = math.min(size.width, size.height) / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.grey.withValues(alpha: 0.2);
    canvas.drawCircle(center, r, base);

    if (b == null) return;
    final total = (b!.q1 + b!.q2 + b!.q3 + b!.q4).clamp(1, 1 << 30);
    final paints = [
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE84545),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF4996E),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF2B705),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9CA3AF),
    ];
    final values = [b!.q1, b!.q2, b!.q3, b!.q4];
    double start = -math.pi / 2;
    for (int i = 0; i < 4; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, false, paints[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.b != b;
}

