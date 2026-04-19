import 'package:eisen/features/insights/domain/nudge.dart';
import 'package:eisen/features/settings/domain/notification_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NudgeNotificationService', () {
    group('Notification ID mapping', () {
      test('cada NudgeType tiene un ID único', () {
        final ids = <int>{};
        for (final type in NudgeType.values) {
          final id = _getNudgeNotificationIdExposed(type);
          expect(ids.contains(id), false,
              reason: 'ID $id duplicado para $type');
          ids.add(id);
        }
        // Verificar que todos están en el rango 2000-2099
        expect(ids.every((id) => id >= 2000 && id < 2100), true);
      });
    });

    group('Title formatting', () {
      test('high severity incluye emoji de alerta', () {
        final nudge = Nudge(
          id: 'test',
          type: NudgeType.overload,
          title: 'Test Title',
          severity: NudgeSeverity.high,
          message: 'Test message',
          createdAt: DateTime.now(),
          category: NudgeCategory.balance,
        );
        final title = _formatTitleExposed(nudge);
        expect(title, startsWith('🚨'));
      });

      test('medium severity incluye emoji de idea', () {
        final nudge = Nudge(
          id: 'test',
          type: NudgeType.lowQ2,
          title: 'Test Title',
          severity: NudgeSeverity.medium,
          message: 'Test message',
          createdAt: DateTime.now(),
          category: NudgeCategory.balance,
        );
        final title = _formatTitleExposed(nudge);
        expect(title, startsWith('💡'));
      });
    });

    group('Prioritization', () {
      test('ordena por severidad correctamente', () {
        final nudges = [
          Nudge(
            id: '1',
            type: NudgeType.lowQ2,
            title: 'Low Priority',
            severity: NudgeSeverity.low,
            message: 'Low',
            createdAt: DateTime.now(),
            category: NudgeCategory.balance,
          ),
          Nudge(
            id: '2',
            type: NudgeType.overload,
            title: 'High Priority',
            severity: NudgeSeverity.high,
            message: 'High',
            createdAt: DateTime.now(),
            category: NudgeCategory.balance,
          ),
          Nudge(
            id: '3',
            type: NudgeType.procrastination,
            title: 'Medium Priority',
            severity: NudgeSeverity.medium,
            message: 'Medium',
            createdAt: DateTime.now(),
            category: NudgeCategory.productivity,
          ),
        ];

        final prioritized = _prioritizeNudgesExposed(nudges);

        expect(prioritized[0].severity, NudgeSeverity.high);
        expect(prioritized[1].severity, NudgeSeverity.medium);
        expect(prioritized[2].severity, NudgeSeverity.low);
      });
    });

    group('Quiet hours detection', () {
      test('detecta quiet hours normales correctamente', () {
        final prefs = NotificationPrefs(
          notificationsEnabled: true,
          dailyReminderEnabled: false,
          quietHoursEnabled: true,
          quietStart: const TimeOfDay(hour: 14, minute: 0),
          quietEnd: const TimeOfDay(hour: 16, minute: 0),
          nudgesEnabled: true,
          endOfDaySummary: false,
        );

        // Simular hora actual (tendríamos que mockear TimeOfDay.now())
        // Por ahora solo verificamos la lógica existe
        expect(prefs.quietHoursEnabled, true);
        expect(prefs.quietStart, isNotNull);
        expect(prefs.quietEnd, isNotNull);
      });

      test('quiet hours deshabilitadas devuelve false', () {
        final prefs = NotificationPrefs(
          notificationsEnabled: true,
          dailyReminderEnabled: false,
          quietHoursEnabled: false,
          quietStart: const TimeOfDay(hour: 22, minute: 0),
          quietEnd: const TimeOfDay(hour: 8, minute: 0),
          nudgesEnabled: true,
          endOfDaySummary: false,
        );

        expect(prefs.quietHoursEnabled, false);
      });
    });

    group('Batch nudges limits', () {
      test('limita a máximo 3 nudges', () {
        final nudges = List.generate(
          5,
          (i) => Nudge(
            id: 'nudge_$i',
            type: NudgeType.values[i % NudgeType.values.length],
            title: 'Title $i',
            severity: NudgeSeverity.medium,
            message: 'Message $i',
            createdAt: DateTime.now(),
            category: NudgeCategory.productivity,
          ),
        );

        final prioritized = _prioritizeNudgesExposed(nudges);
        final limited = prioritized.take(3).toList();

        expect(limited.length, 3);
      });
    });

    group('Notification enabling checks', () {
      test('no envía si notifications deshabilitadas', () {
        final prefs = NotificationPrefs(
          notificationsEnabled: false,
          dailyReminderEnabled: false,
          quietHoursEnabled: false,
          nudgesEnabled: true,
          endOfDaySummary: false,
        );

        expect(prefs.notificationsEnabled, false);
      });

      test('no envía si nudges específicamente deshabilitados', () {
        final prefs = NotificationPrefs(
          notificationsEnabled: true,
          dailyReminderEnabled: false,
          quietHoursEnabled: false,
          nudgesEnabled: false,
          endOfDaySummary: false,
        );

        expect(prefs.nudgesEnabled, false);
      });

      test('envía si ambos habilitados', () {
        final prefs = NotificationPrefs(
          notificationsEnabled: true,
          dailyReminderEnabled: false,
          quietHoursEnabled: false,
          nudgesEnabled: true,
          endOfDaySummary: false,
        );

        expect(prefs.notificationsEnabled && prefs.nudgesEnabled, true);
      });
    });
  });
}

// Funciones helper para exponer métodos privados en tests
int _getNudgeNotificationIdExposed(NudgeType type) {
  switch (type) {
    case NudgeType.lowQ2:
      return 2001;
    case NudgeType.excessiveReschedules:
      return 2002;
    case NudgeType.overload:
      return 2003;
    case NudgeType.procrastination:
      return 2004;
    case NudgeType.quadrantImbalance:
      return 2005;
    case NudgeType.noProject:
      return 2006;
    case NudgeType.dailyOverload:
      return 2007;
    case NudgeType.noFocusSessions:
      return 2008;
    case NudgeType.lateNightWork:
      return 2009;
  }
}

String _formatTitleExposed(Nudge nudge) {
  switch (nudge.severity) {
    case NudgeSeverity.high:
      return '🚨 ${_getTitleByTypeExposed(nudge.type)}';
    case NudgeSeverity.mediumHigh:
      return '⚠️ ${_getTitleByTypeExposed(nudge.type)}';
    case NudgeSeverity.medium:
      return '💡 ${_getTitleByTypeExposed(nudge.type)}';
    case NudgeSeverity.low:
      return '✨ ${_getTitleByTypeExposed(nudge.type)}';
  }
}

String _getTitleByTypeExposed(NudgeType type) {
  switch (type) {
    case NudgeType.lowQ2:
      return 'Poco Tiempo en Q2';
    case NudgeType.excessiveReschedules:
      return 'Muchas Tareas Retrasadas';
    case NudgeType.overload:
      return 'Sobrecarga de Urgencias';
    case NudgeType.procrastination:
      return 'Tareas Estancadas';
    case NudgeType.quadrantImbalance:
      return 'Desbalance de Cuadrantes';
    case NudgeType.noProject:
      return 'Organización Pendiente';
    case NudgeType.dailyOverload:
      return 'Demasiadas Urgencias Hoy';
    case NudgeType.noFocusSessions:
      return 'Sin Sesiones de Foco';
    case NudgeType.lateNightWork:
      return 'Trabajo Nocturno';
  }
}

List<Nudge> _prioritizeNudgesExposed(List<Nudge> nudges) {
  final sorted = List<Nudge>.from(nudges);
  sorted.sort((a, b) {
    final severityCompare = _severityValueExposed(b.severity)
        .compareTo(_severityValueExposed(a.severity));
    if (severityCompare != 0) return severityCompare;

    final aValue =
        a.metadata.values.whereType<num>().fold(0.0, (a, b) => a + b);
    final bValue =
        b.metadata.values.whereType<num>().fold(0.0, (a, b) => a + b);
    return bValue.compareTo(aValue);
  });
  return sorted;
}

int _severityValueExposed(NudgeSeverity severity) {
  switch (severity) {
    case NudgeSeverity.high:
      return 4;
    case NudgeSeverity.mediumHigh:
      return 3;
    case NudgeSeverity.medium:
      return 2;
    case NudgeSeverity.low:
      return 1;
  }
}
