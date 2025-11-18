import 'package:eisen/features/stats/domain/models.dart';
import 'package:flutter/material.dart';

import 'donut_balance.dart';

class EisenhowerBalanceSection extends StatelessWidget {
  const EisenhowerBalanceSection({super.key, this.balance});

  final BalanceBreakdown? balance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerLow;
    final radius = BorderRadius.circular(12);
    final b = balance;

    String interpretation = '';
    if (b != null) {
      final total =
          (b.q1 + b.q2 + b.q3 + b.q4).clamp(1, 1 << 30).toDouble();
      final q1Share = b.q1 / total;
      final q2Share = b.q2 / total;
      final q3Share = b.q3 / total;
      final q4Share = b.q4 / total;

      if (q2Share >= 0.30 && q1Share <= 0.40) {
        interpretation =
            'Buen balance: dedicas suficiente tiempo a lo importante (Q2).';
      } else if (q1Share > 0.50) {
        interpretation =
            'Estás concentrando mucho tiempo en urgencias (Q1). Cuida tu Q2.';
      } else if (q3Share + q4Share > 0.40) {
        interpretation =
            'Parte de tu tiempo se va en tareas poco importantes. Revisa tu Q2.';
      } else {
        interpretation =
            'Balance razonable entre urgente e importante. Ajusta pequeños detalles.';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Eisenhower',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: DonutBalance(balance: balance),
          ),
          if (interpretation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              interpretation,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

