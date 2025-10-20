import 'package:flutter/material.dart';
import '../../domain/models.dart';

class CardFocus extends StatelessWidget {
  final WeeklyStats? weekly;
  const CardFocus({super.key, this.weekly});

  @override
  Widget build(BuildContext context) {
    final w = weekly;
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foco', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (w == null) const Text('Cargando…') else ...[
              Text('Minutos de foco (semana): ${w.focusMinutes}'),
              Text('Q2 share: ${(w.q2Share * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
      ),
    );
  }
}

