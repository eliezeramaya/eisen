import 'dart:convert';

import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UiPrefsData general fields roundtrip', () {
    final a = UiPrefsData(
      languageCode: 'es',
      regionCode: 'MX',
      dateFormat: 'yyyy-MM-dd',
      use24h: false,
      dailyReminderTime: '09:30',
      endOfDaySummary: true,
      endOfDayTime: '21:45',
      pomodoroAlert: 'visual',
      notificationTone: 'bell',
      workflowPlanEnabled: true,
      textScaleLevel: 4,
    );

    final json = a.toJson();
    final b = UiPrefsData.fromJson(json);

    expect(b.languageCode, 'es');
    expect(b.regionCode, 'MX');
    expect(b.dateFormat, 'yyyy-MM-dd');
    expect(b.use24h, isFalse);
    expect(b.dailyReminderTime, '09:30');
    expect(b.endOfDaySummary, isTrue);
    expect(b.endOfDayTime, '21:45');
    expect(b.pomodoroAlert, 'visual');
    expect(b.notificationTone, 'bell');
    expect(b.workflowPlanEnabled, isTrue);
    expect(b.textScaleLevel, 4);
  });

  test('UiPrefsData normalizes legacy pomodoroAlert values', () {
    final legacySilent = jsonEncode(
      const UiPrefsData(pomodoroAlert: 'sound').copyWith().toJson()
        ..['pomodoroAlert'] = 'silent',
    );
    final legacyVibration = jsonEncode(
      const UiPrefsData(pomodoroAlert: 'sound').copyWith().toJson()
        ..['pomodoroAlert'] = 'vibration',
    );

    final decodedSilent =
        UiPrefsData.fromJson(jsonDecode(legacySilent) as Map<String, Object?>);
    final decodedVibration = UiPrefsData.fromJson(
        jsonDecode(legacyVibration) as Map<String, Object?>);

    expect(decodedSilent.pomodoroAlert, 'none');
    expect(decodedVibration.pomodoroAlert, 'visual');
  });
}

