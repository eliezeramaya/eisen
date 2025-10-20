import 'package:flutter/material.dart';
import '../../domain/models.dart';
import 'sparkline.dart';

class CardTrends extends StatelessWidget {
  final List<TrendPoint>? trend;
  const CardTrends({super.key, this.trend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tendencias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Sparkline(trend: trend),
          ],
        ),
      ),
    );
  }
}

