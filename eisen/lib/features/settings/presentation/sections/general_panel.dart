import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/notifications/notifications_service.dart';

class GeneralPanel extends ConsumerWidget {
  const GeneralPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uiPrefsProvider);
    return ListView(
      children: [
        const _SectionHeader(title: 'Language & Region', subtitle: 'Idioma, región y formatos de fecha/hora'),
        _LanguageRegionCard(prefs: prefs),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Text & Readability', subtitle: 'Escala de texto y legibilidad'),
        _TextScaleCard(prefs: prefs),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Notifications', subtitle: 'Recordatorios diarios y alertas'),
        _NotificationsCard(prefs: prefs),
      ],
    );
  }
}

class _TextScaleCard extends ConsumerWidget {
  final UiPrefsData prefs;
  const _TextScaleCard({required this.prefs});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.text_fields),
              title: const Text('Tamaño de texto'),
              subtitle: const Text('Ajusta la escala del texto en toda la app (1–5).'),
            ),
            Slider(
              value: prefs.textScaleLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: prefs.textScaleLevel.toString(),
              onChanged: (d) => ctrl.setTextScaleLevel(d.round()),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Actual: ${prefs.textScaleLevel}/5', style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRegionCard extends ConsumerWidget {
  final UiPrefsData prefs;
  const _LanguageRegionCard({required this.prefs});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DropdownRow(
            label: 'Idioma',
            value: prefs.languageCode,
            items: const ['system','en','es'],
            itemLabel: (v) => {'system':'Sistema','en':'English','es':'Español'}[v]!,
            onChanged: (v) { if (v != null) ctrl.setLanguageCode(v); },
          ),
          _DropdownRow(
            label: 'Región',
            value: prefs.regionCode,
            items: const ['system','US','MX','ES'],
            itemLabel: (v) => {'system':'Sistema','US':'Estados Unidos','MX':'México','ES':'España'}[v]!,
            onChanged: (v) { if (v != null) ctrl.setRegionCode(v); },
          ),
          _DropdownRow(
            label: 'Formato de Fecha',
            value: prefs.dateFormat,
            items: const ['dd/MM/yyyy','MM/dd/yyyy','yyyy-MM-dd'],
            itemLabel: (v) => v,
            onChanged: (v) { if (v != null) ctrl.setDateFormat(v); },
          ),
          SwitchListTile(
            title: const Text('24-hour time'),
            subtitle: const Text('Usar formato 24h para la hora'),
            value: prefs.use24h,
            onChanged: ctrl.setUse24h,
          ),
        ]),
      ),
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  final UiPrefsData prefs;
  const _NotificationsCard({required this.prefs});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(uiPrefsControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _TimePickerRow(
            label: 'Daily focus reminder',
            hhmm24: prefs.dailyReminderTime,
            onPicked: (hhmm) async {
              await ctrl.setDailyReminderTime(hhmm);
              // Notifications not supported on web
              // try {
              //   await NotificationsService.scheduleDaily(
              //     id: 1001,
              //     time: hhmm,
              //     title: 'Focus time',
              //     body: 'Planifica tu día ahora',
              //   );
              // } catch (_) {}
            },
            onClear: () async {
              await ctrl.setDailyReminderTime('');
              // await NotificationsService.cancel(1001);
            },
          ),
          SwitchListTile(
            title: const Text('End-of-day summary'),
            subtitle: const Text('Recibe un resumen de pendientes al finalizar el día'),
            value: prefs.endOfDaySummary,
            onChanged: (v) async {
              await ctrl.setEndOfDaySummary(v);
              if (!v) await NotificationsService.cancel(1002);
            },
          ),
          if (prefs.endOfDaySummary)
            _TimePickerRow(
              label: 'Summary time',
              hhmm24: prefs.endOfDayTime,
              onPicked: (hhmm) async {
                await ctrl.setEndOfDayTime(hhmm);
                // Notifications not supported on web
                // try {
                //   await NotificationsService.scheduleDaily(
                //     id: 1002,
                //     time: _toTime(hhmm),
                //     title: 'Resumen del día',
                //     body: 'Revisa tus tareas',
                //   );
                // } catch (_) {}
              },
              onClear: () async {
                await ctrl.setEndOfDayTime('');
                // await NotificationsService.cancel(1002);
              },
            ),
          const SizedBox(height: 8),
                    _DropdownRow(
            label: 'Alerta Pomodoro',
            value: prefs.pomodoroAlert,
            items: const ['none','sound','visual'],
            itemLabel: (v) => {'none':'Ninguna','sound':'Sonido','visual':'Visual'}[v]!,
            onChanged: (v) { if (v != null) ctrl.setPomodoroAlert(v); },
          ),
                    _DropdownRow(
            label: 'Tono de Notificación',
            value: prefs.notificationTone,
            items: const ['default','chime','bell'],
            itemLabel: (v) => {'default':'Default','chime':'Chime','bell':'Bell'}[v]!,
            onChanged: (v) { if (v != null) ctrl.setNotificationTone(v); },
          ),
        ]),
      ),
    );
  }

  // Time parsing - not used on web
  // Time _toTime(String hhmm) {
  //   if (hhmm.isEmpty) return Time(9, 0);
  //   final parts = hhmm.split(':');
  //   return Time(int.parse(parts[0]), int.parse(parts[1]));
  // }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final String Function(String) itemLabel;
  final ValueChanged<String?> onChanged;
  const _DropdownRow({super.key, required this.label, required this.value, required this.items, required this.itemLabel, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((e)=>DropdownMenuItem(value: e, child: Text(itemLabel(e)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label, hhmm24;
  final ValueChanged<String> onPicked;
  final VoidCallback onClear;
  const _TimePickerRow({super.key, required this.label, required this.hhmm24, required this.onPicked, required this.onClear});
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
            final picked = await showTimePicker(context: context, initialTime: now);
            if (picked != null) {
              final hh = picked.hour.toString().padLeft(2,'0');
              final mm = picked.minute.toString().padLeft(2,'0');
              onPicked('$hh:$mm');
            }
          },
        ),
      ]),
    );
  }
}

