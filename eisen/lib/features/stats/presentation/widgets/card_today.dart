import 'package:flutter/material.dart';
import 'package:eisen/features/stats/domain/models.dart';
import 'streak_bar.dart';

/// Card showing today's focus and streak preview.
class CardToday extends StatelessWidget {
  final WeeklyStats? weekly;
  final int streak;
  const CardToday({super.key, required this.weekly, required this.streak});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              StreakBar(daysActive: streak.clamp(0, 7)),
              const SizedBox(width: 8),
              Text('${streak}d streak', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('Foco semanal: ${weekly?.focusMinutes ?? 0} min'),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(elevation: 0.5, child: child);
  }
}

