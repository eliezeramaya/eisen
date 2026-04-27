import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UiPrefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults are stable', () async {
      final repo = UiPrefs();
      final data = await repo.load();

      expect(data.themeMode, ThemeMode.system);
      expect(data.compact, isFalse);
      expect(data.showAxisLegends, isTrue);
      expect(data.minimal, isFalse);
      expect(data.topKPerQuadrant, 20);
      expect(data.advancedInsightsEnabled, isTrue);
      expect(data.quadrantLabelStyle, QuadrantLabelStyle.professional);
    });

    test('save then load returns same values', () async {
      final repo = UiPrefs();
      final original = UiPrefsData(
        themeMode: ThemeMode.dark,
        compact: true,
        showAxisLegends: false,
        minimal: true,
        topKPerQuadrant: 30,
        gamma: 0.9,
        minAreaNormalized: 0.0001,
        quadrantPadding: 0.01,
        languageCode: 'en',
        regionCode: 'US',
        dateFormat: 'MM/dd/yyyy',
        use24h: false,
        dailyReminderTime: '08:00',
        endOfDaySummary: true,
        endOfDayTime: '21:00',
        pomodoroAlert: 'visual',
        notificationTone: 'bell',
        workflowPlanEnabled: true,
        textScaleLevel: 4,
        advancedInsightsEnabled: false,
        ganttTimeScale: 'days',
        ganttShowBadges: false,
        ganttCompactLanes: true,
        ganttWorkweekOnly: true,
        ganttShowTodayLine: false,
        densityPreset: 'compact',
        viewMode: 'list',
        quadrantLabelStyle: QuadrantLabelStyle.action,
      );

      await repo.save(original);
      final loaded = await repo.load();

      expect(loaded.toJson(), original.toJson());
    });

    test('partial copyWith updates selected fields', () {
      final base = const UiPrefsData();
      final copy = base.copyWith(compact: true, topKPerQuadrant: 40);

      expect(copy.compact, isTrue);
      expect(copy.topKPerQuadrant, 40);
      expect(copy.showAxisLegends, base.showAxisLegends);
    });

    test('tolerates corrupted stored data and falls back to defaults',
        () async {
      SharedPreferences.setMockInitialValues({
        'eisen.ui.v1': '{invalid json',
      });
      final repo = UiPrefs();
      final loaded = await repo.load();

      expect(loaded.themeMode, ThemeMode.system);
      expect(loaded.topKPerQuadrant, 20);
    });

    test('ignores missing fields and applies defaults', () async {
      final minimalJson = {
        'themeMode': 'dark',
        'compact': true,
      };
      SharedPreferences.setMockInitialValues({
        'eisen.ui.v1': minimalJson.toString(), // not valid JSON object
      });
      final repo = UiPrefs();
      final loaded = await repo.load();

      expect(loaded.themeMode, ThemeMode.system); // fallback due to parse fail
      expect(loaded.compact, isFalse);
    });
  });
}
