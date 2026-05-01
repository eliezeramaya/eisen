import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/domain/enums/automation_mode.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutomationModeSection extends ConsumerWidget {
  const AutomationModeSection({super.key});

  static const double _minWidthForInlineModes = 760;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(classificationSettingsControllerProvider);
    final controller =
        ref.read(classificationSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Automation mode',
          subtitle:
              'Define cuánto decide la app durante captura, guardado y visualización.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < _minWidthForInlineModes;
            final children = [
              for (final mode in AutomationMode.values)
                _ModeCard(
                  mode: mode,
                  selected: settings.automationMode == mode,
                  onTap: () => controller.updateAutomationMode(mode),
                ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  Expanded(child: children[i]),
                  if (i != children.length - 1) const SizedBox(width: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AutomationMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = switch (mode) {
      AutomationMode.manualOnly => cs.tertiary,
      AutomationMode.assisted => cs.primary,
      AutomationMode.automatic => cs.secondary,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? color.withValues(alpha: 0.12) : cs.surface,
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.7)
                  : cs.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(mode), color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mode.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                mode.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final line in _bulletsFor(mode))
                    Chip(
                      avatar: Icon(Icons.bolt, size: 14, color: color),
                      label: Text(line),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(AutomationMode mode) {
  return switch (mode) {
    AutomationMode.manualOnly => Icons.edit_outlined,
    AutomationMode.assisted => Icons.auto_awesome_outlined,
    AutomationMode.automatic => Icons.psychology_alt_outlined,
  };
}

List<String> _bulletsFor(AutomationMode mode) {
  return switch (mode) {
    AutomationMode.manualOnly => const [
        'Sugiere antes de guardar',
        'Resalta clasificación editable',
      ],
    AutomationMode.assisted => const [
        'Guarda automático',
        'Permite corregir rápido',
      ],
    AutomationMode.automatic => const [
        'Clasifica sin preguntar',
        'Afecta filtros y agrupación',
      ],
  };
}
