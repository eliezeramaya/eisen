import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/core/design_system/widgets/eisen_button.dart';
import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/focus/domain/focus_session.dart';
import 'package:flutter/material.dart';

/// Base UI for Focus/Pomodoro flows (logic to be added in later phases).
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  FocusSessionType _type = FocusSessionType.deepWork;
  int _durationMinutes = 50;
  String? _linkedTask;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cs = Theme.of(context).colorScheme;
    final showBack = width < 720;
    final durations = switch (_type) {
      FocusSessionType.deepWork => const [50, 75, 90, 120],
      FocusSessionType.sprint => const [25, 35, 45, 60],
      FocusSessionType.pomodoro => const [20, 25, 30, 40],
    };
    _durationMinutes = durations.contains(_durationMinutes)
        ? _durationMinutes
        : durations.first;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Modo de foco'),
        leading: showBack
            ? BackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EisenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EisenSectionHeader(title: 'Tipo de sesión'),
              const SizedBox(height: EisenSpacing.sm),
              Wrap(
                spacing: EisenSpacing.sm,
                runSpacing: EisenSpacing.sm,
                children: FocusSessionType.values.map((type) {
                  final label = switch (type) {
                    FocusSessionType.deepWork => 'Deep Work',
                    FocusSessionType.sprint => 'Sprint',
                    FocusSessionType.pomodoro => 'Pomodoro',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: _type == type,
                    onSelected: (_) =>
                        setState(() => _type = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: EisenSpacing.lg),
              EisenCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EisenSectionHeader(
                      title: 'Duración',
                      subtitle: 'Ajusta la longitud del bloque',
                    ),
                    const SizedBox(height: EisenSpacing.sm),
                    Wrap(
                      spacing: EisenSpacing.sm,
                      children: durations.map((d) {
                        return ChoiceChip(
                          label: Text('$d min'),
                          selected: _durationMinutes == d,
                          onSelected: (_) =>
                              setState(() => _durationMinutes = d),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EisenSpacing.lg),
              EisenCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EisenSectionHeader(
                      title: 'Tarea vinculada',
                      subtitle:
                          'Opcional: asigna la sesión a una tarea',
                    ),
                    const SizedBox(height: EisenSpacing.sm),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: _linkedTask,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin tarea vinculada'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _linkedTask = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EisenSpacing.xl),
              EisenButton.primary(
                label: 'Iniciar foco',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  // Placeholder hook for future focus logic.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Focus se iniciará próximamente'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
