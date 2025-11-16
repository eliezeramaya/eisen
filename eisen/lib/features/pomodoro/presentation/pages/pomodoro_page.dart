import 'package:flutter/material.dart';

/// Simple placeholder page for a Pomodoro timer.
///
/// This keeps navigation wired up from the top toolbar; the
/// actual timer logic can be iterated on separately.
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final title = 'Pomodoro';
    final subtitle = isEs
        ? 'Temporizador Pomodoro (en construcción)'
        : 'Pomodoro timer (coming soon)';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

