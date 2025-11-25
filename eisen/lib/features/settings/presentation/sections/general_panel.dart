import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/insights/domain/nudge_controller.dart';
import 'package:eisen/features/settings/application/appearance_preview_controller.dart';
import 'package:eisen/features/settings/domain/language_controller.dart';
import 'package:eisen/features/settings/domain/notification_prefs_controller.dart';
import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:eisen/features/settings/presentation/widgets/tone_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralPanel extends ConsumerWidget {
  const GeneralPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPrefsProvider);
    return ListView(
      children: [
        const EisenSectionHeader(
          title: 'Language & Region',
          subtitle: 'Idioma, región y formatos de fecha/hora',
        ),
        _LanguageRegionCard(prefs: prefs),
        const SizedBox(height: 24),
        const EisenSectionHeader(
          title: 'Text & Readability',
          subtitle: 'Escala de texto y legibilidad',
        ),
        _TextScaleCard(prefs: prefs),
        const SizedBox(height: 24),
        const EisenSectionHeader(
          title: 'Notifications',
          subtitle: 'Recordatorios diarios y alertas',
        ),
        const _NotificationsCard(),
        const SizedBox(height: 24),
        const EisenSectionHeader(
          title: 'Nudges inteligentes',
          subtitle: 'Controla recomendaciones y vista previa',
        ),
        const _NudgesCard(),
        const SizedBox(height: 24),
        const EisenSectionHeader(
          title: 'Workflow',
          subtitle: 'Activa el modo plan de trabajo',
        ),
        _WorkflowCard(prefs: prefs),
        const SizedBox(height: 24),
        const EisenSectionHeader(
          title: 'IA y personalización',
          subtitle: 'Control de insights avanzados y privacidad',
        ),
        _AiCard(prefs: prefs),
      ],
    );
  }
}

/// Standalone panel for Language & Region settings (used on mobile).
class LanguageRegionPanel extends ConsumerWidget {
  const LanguageRegionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPrefsProvider);
    return ListView(
      children: [
        const _SectionHeader(
          title: 'Language & Region',
          subtitle: 'Idioma, región y formatos de fecha/hora',
        ),
        _LanguageRegionCard(prefs: prefs),
      ],
    );
  }
}

/// Standalone panel for Notifications settings (used on mobile).
class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const _SectionHeader(
          title: 'Notifications',
          subtitle: 'Recordatorios diarios y alertas',
        ),
        const _NotificationsCard(),
      ],
    );
  }
}

/// Standalone text scale card (used in Accessibility).
class TextScaleCard extends ConsumerWidget {
  const TextScaleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPrefsProvider);
    return _TextScaleCard(prefs: prefs);
  }
}

class _TextScaleCard extends ConsumerWidget {
  const _TextScaleCard({required this.prefs});
  final UiPrefsData prefs;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    final preview = ref.read(appearancePreviewProvider.notifier);
    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.text_fields),
            title: Text('Tamaño de texto'),
            subtitle: Text('Ajusta la escala del texto en toda la app (1–5).'),
          ),
          Slider(
            value: prefs.textScaleLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: prefs.textScaleLevel.toString(),
            onChanged: (d) {
              final level = d.round().clamp(1, 5);
              ctrl.setTextScaleLevel(level);
              preview.setTextScaleLevel(level);
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Actual: ${prefs.textScaleLevel}/5',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRegionCard extends ConsumerWidget {
  const _LanguageRegionCard({required this.prefs});
  final UiPrefsData prefs;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    final langAsync = ref.watch(languageControllerProvider);
    final locale = langAsync.maybeWhen(
      data: (v) => v.locale,
      orElse: () => null,
    );
    final languageValue = locale?.languageCode ?? 'system';
    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DropdownRow(
            label: 'Idioma',
            value: languageValue,
            items: const ['system', 'en', 'es'],
            itemLabel: (v) =>
                {'system': 'Sistema', 'en': 'English', 'es': 'Español'}[v]!,
            onChanged: (v) {
              if (v == null) return;
              if (v == 'system') {
                ref.read(languageControllerProvider.notifier).setLocale(null);
              } else {
                ref
                    .read(languageControllerProvider.notifier)
                    .setLocale(Locale(v));
              }
            },
          ),
          _DropdownRow(
            label: 'Región',
            value: prefs.regionCode,
            items: const ['system', 'US', 'MX', 'ES'],
            itemLabel: (v) => {
              'system': 'Sistema',
              'US': 'Estados Unidos',
              'MX': 'México',
              'ES': 'España'
            }[v]!,
            onChanged: (v) {
              if (v != null) ctrl.setRegionCode(v);
            },
          ),
          _DropdownRow(
            label: 'Formato de Fecha',
            value: prefs.dateFormat,
            items: const ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'],
            itemLabel: (v) => v,
            onChanged: (v) {
              if (v != null) ctrl.setDateFormat(v);
            },
          ),
          SwitchListTile(
            title: const Text('24-hour time'),
            subtitle: const Text('Usar formato 24h para la hora'),
            value: prefs.use24h,
            onChanged: ctrl.setUse24h,
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = ref.watch(notificationPrefsControllerProvider);
    final ctrl = ref.read(notificationPrefsControllerProvider.notifier);
    final prefs = asyncPrefs.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notificaciones',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: prefs?.notificationsEnabled ?? true,
                onChanged: (v) => ctrl.toggleNotifications(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: asyncPrefs.isLoading
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox.shrink(),
          ),
          if (prefs != null) ...[
            SwitchListTile(
              title: const Text('Recordatorio diario'),
              subtitle: const Text('Te recuerda bloquear tu foco en la mañana'),
              value: prefs.dailyReminderEnabled,
              onChanged: (v) => ctrl.toggleDailyReminder(v),
            ),
            if (prefs.dailyReminderEnabled)
              _TimePickerRow(
                label: 'Hora del recordatorio',
                hhmm24: _fmtTime(prefs.dailyReminderTime),
                onPicked: (t) => ctrl.setDailyReminderTime(t),
                onClear: () => ctrl.setDailyReminderTime(null),
              ),
            SwitchListTile(
              title: const Text('Resumen de fin de día'),
              subtitle: const Text('Repasa pendientes y wins'),
              value: prefs.endOfDaySummary,
              onChanged: (v) => ctrl.toggleEndOfDaySummary(v),
            ),
            if (prefs.endOfDaySummary)
              _TimePickerRow(
                label: 'Hora del resumen',
                hhmm24: _fmtTime(prefs.endOfDayTime),
                onPicked: (t) => ctrl.setEndOfDayTime(t),
                onClear: () => ctrl.setEndOfDayTime(null),
              ),
            const Divider(),
            SwitchListTile(
              title: const Text('Horas silenciosas'),
              subtitle: const Text('Evita alertas en la noche'),
              value: prefs.quietHoursEnabled,
              onChanged: (v) => ctrl.toggleQuietHours(v),
            ),
            if (prefs.quietHoursEnabled)
              _QuietHoursRow(
                start: prefs.quietStart,
                end: prefs.quietEnd,
                onChanged: (start, end) => ctrl.setQuietHours(start, end),
              ),
            const Divider(),
            _DropdownRow(
              label: 'Alerta Pomodoro',
              value: prefs.pomodoroAlert,
              items: const ['none', 'sound', 'visual'],
              itemLabel: (v) => {
                'none': 'Ninguna',
                'sound': 'Sonido',
                'visual': 'Visual'
              }[v]!,
              onChanged: (v) {
                if (v != null) ctrl.setPomodoroAlert(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Tono de notificación'),
              subtitle: Text(prefs.notificationTone.labelEs),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => showToneSelectorSheet(context),
            ),
            const SizedBox(height: 6),
            Text(
              'Los horarios se respetan salvo que desactives las notificaciones.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ]),
      ),
    );
  }
}

class _NudgesCard extends ConsumerWidget {
  const _NudgesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrefs = ref.watch(notificationPrefsControllerProvider);
    final ctrl = ref.read(notificationPrefsControllerProvider.notifier);
    final prefs = asyncPrefs.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );
    final cs = Theme.of(context).colorScheme;

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nudges en la app y por notificación',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: prefs?.nudgesEnabled ?? true,
                onChanged: (v) => ctrl.toggleNudges(v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Recomendaciones basadas en tus patrones. Máximo 1 al día.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          EisenCard(
            outlined: true,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.notifications, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muy poco tiempo en lo importante',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'En los últimos días casi no has trabajado en tareas Q2. Agenda un bloque ahora.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Esto es un ejemplo de notificación.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Iniciar bloque de foco'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Los nudges respetan las horas silenciosas y tus preferencias de notificaciones.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends ConsumerWidget {
  const _WorkflowCard({required this.prefs});
  final UiPrefsData prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Workflow plan'),
            subtitle: const Text(
                'Muestra un botón con vista tipo Gantt en la barra superior'),
            value: prefs.workflowPlanEnabled,
            onChanged: ctrl.setWorkflowPlanEnabled,
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando está activo, verás un icono de líneas temporales en el menú superior.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _AiCard extends ConsumerWidget {
  const _AiCard({required this.prefs});
  final UiPrefsData prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiCtrl = ref.read(uiPrefsControllerProvider.notifier);
    final nudgesCtrl = ref.read(nudgeControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return EisenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Usar insights avanzados (IA)'),
            subtitle: const Text(
                'Eisen analiza tus patrones para sugerir mejoras. Puedes desactivarlo cuando quieras.'),
            value: prefs.advancedInsightsEnabled,
            onChanged: uiCtrl.setAdvancedInsightsEnabled,
          ),
          const SizedBox(height: 8),
          Text(
            'Tus datos se usan solo dentro de Eisen para calcular estadísticas e insights. No se comparten con terceros.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () async {
                await nudgesCtrl.resetLearning();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aprendizaje de nudges restablecido'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Restablecer aprendizaje'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow(
      {required this.label,
      required this.value,
      required this.items,
      required this.itemLabel,
      required this.onChanged});
  final String label, value;
  final List<String> items;
  final String Function(String) itemLabel;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e))))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow(
      {required this.label,
      required this.hhmm24,
      required this.onPicked,
      required this.onClear});
  final String label;
  final String hhmm24;
  final ValueChanged<TimeOfDay> onPicked;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(hhmm24.isEmpty ? 'Disabled' : hhmm24),
      trailing: Wrap(spacing: 8, children: [
        OutlinedButton(onPressed: onClear, child: const Text('Clear')),
        FilledButton(
          child: const Text('Pick time'),
          onPressed: () async {
            final now = TimeOfDay.now();
            final picked =
                await showTimePicker(context: context, initialTime: now);
            if (picked != null) {
              onPicked(picked);
            }
          },
        ),
      ]),
    );
  }
}

class _QuietHoursRow extends StatelessWidget {
  const _QuietHoursRow({
    required this.start,
    required this.end,
    required this.onChanged,
  });
  final TimeOfDay? start;
  final TimeOfDay? end;
  final void Function(TimeOfDay start, TimeOfDay end) onChanged;

  Future<TimeOfDay?> _pick(BuildContext context, TimeOfDay? initial) async {
    final base = initial ?? TimeOfDay.now();
    return showTimePicker(context: context, initialTime: base);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final picked = await _pick(context, start);
                if (picked != null) {
                  onChanged(picked, end ?? picked);
                }
              },
              child: Text(
                  'Inicio: ${_fmtTime(start).isEmpty ? '--' : _fmtTime(start)}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final picked = await _pick(context, end);
                if (picked != null) {
                  onChanged(start ?? picked, picked);
                }
              },
              child:
                  Text('Fin: ${_fmtTime(end).isEmpty ? '--' : _fmtTime(end)}'),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtTime(TimeOfDay? t) {
  if (t == null) return '';
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
