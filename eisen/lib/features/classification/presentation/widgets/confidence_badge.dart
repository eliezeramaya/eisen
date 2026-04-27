import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:flutter/material.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.level,
    required this.score,
  });

  final ConfidenceLevel level;
  final double score;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      ConfidenceLevel.low => Colors.redAccent,
      ConfidenceLevel.medium => Colors.orangeAccent,
      ConfidenceLevel.high => Colors.green,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${level.label} ${(score * 100).round()}%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
