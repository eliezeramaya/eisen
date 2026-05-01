import 'dart:async';

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/features/focus/presentation/pages/pomodoro_session_page.dart';
import 'package:eisen/features/focus/presentation/widgets/focus_rhythm_card.dart';
import 'package:eisen/features/focus/presentation/widgets/focus_top_bar.dart';
import 'package:eisen/features/focus/presentation/widgets/focus_window_card.dart';
import 'package:eisen/features/focus/presentation/widgets/quick_focus_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusDashboardPage extends ConsumerStatefulWidget {
  const FocusDashboardPage({
    super.key,
    this.useShellNavigation = false,
  });

  /// True when this page is hosted by AppShell, which owns global navigation.
  final bool useShellNavigation;

  @override
  ConsumerState<FocusDashboardPage> createState() => _FocusDashboardPageState();
}

class _FocusDashboardPageState extends ConsumerState<FocusDashboardPage> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final config = await _showCustomSessionSheet(context);
          if (config != null) {
            if (!context.mounted) return;
            unawaited(Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PomodoroSessionPage(
                  initialDuration: config.duration,
                  presetLabel: config.label,
                  taskTitle: config.taskTitle,
                  sessionType: config.type,
                  autoStart: true,
                ),
              ),
            ));
          }
        },
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EisenSpacing.lg,
            EisenSpacing.md,
            EisenSpacing.lg,
            96,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusTopBar(
                showNavigationActions: !widget.useShellNavigation,
              ),
              const SizedBox(height: 12),
              const FocusRhythmCard(),
              const SizedBox(height: 16),
              const FocusWindowCard(),
              const SizedBox(height: 16),
              const QuickFocusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<PomodoroConfig?> _showCustomSessionSheet(
    BuildContext context,
  ) async {
    double minutes = 45;
    PomodoroSessionType type = PomodoroSessionType.focus;

    return showModalBottomSheet<PomodoroConfig>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                EisenSpacing.lg,
                EisenSpacing.xl,
                EisenSpacing.lg,
                EisenSpacing.xl + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nueva sesión personalizada',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: EisenSpacing.lg),
                  Text(
                    'Duración (${minutes.round()} min)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: minutes,
                    min: 15,
                    max: 120,
                    divisions: 21,
                    label: '${minutes.round()} min',
                    onChanged: (v) => setState(() => minutes = v),
                  ),
                  const SizedBox(height: EisenSpacing.md),
                  Text(
                    'Tipo de sesión',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: EisenSpacing.sm),
                  Wrap(
                    spacing: EisenSpacing.sm,
                    children: PomodoroSessionType.values.map((t) {
                      final selected = t == type;
                      final label = switch (t) {
                        PomodoroSessionType.focus => 'Focus',
                        PomodoroSessionType.breakSession => 'Break',
                        PomodoroSessionType.deepWork => 'Deep work',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => type = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: EisenSpacing.md),
                  TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Tarea o nota (opcional)',
                    ),
                  ),
                  const SizedBox(height: EisenSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          PomodoroConfig(
                            duration: Duration(minutes: minutes.round()),
                            label:
                                '${minutes.round()} min – ${_labelForType(type)}',
                            type: type,
                            taskTitle: _taskController.text.isEmpty
                                ? null
                                : _taskController.text,
                          ),
                        );
                      },
                      child: const Text('Iniciar sesión'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(_taskController.clear);
  }
}

String _labelForType(PomodoroSessionType type) {
  return switch (type) {
    PomodoroSessionType.focus => 'Focus',
    PomodoroSessionType.breakSession => 'Break',
    PomodoroSessionType.deepWork => 'Deep work',
  };
}
