import 'package:flutter/material.dart';

class CardNudges extends StatelessWidget {
  const CardNudges({super.key});

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final msgs = [
      isEs ? 'Tu balance Q2 luce saludable.' : 'Your Q2 balance looks healthy.',
      isEs ? 'Buen ritmo esta semana. Sigue fluido.' : 'Good pace this week. Keep flowing.',
    ];
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEs ? 'Sugerencias' : 'Nudges', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final m in msgs) Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [const Text('• '), Expanded(child: Text(m))]),
            ),
          ],
        ),
      ),
    );
  }
}

