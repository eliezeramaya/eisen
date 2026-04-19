import 'package:eisen/features/settings/data/accessibility_prefs_repository.dart';
import 'package:eisen/features/settings/data/language_prefs_repository.dart';
import 'package:eisen/features/settings/data/notification_prefs_repository.dart';
import 'package:eisen/features/settings/domain/language_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferences integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('multiple repositories coexist without key collisions', () async {
      final notifRepo = NotificationPrefsLocalRepository();
      final langRepo = LanguagePrefsLocalRepository();
      final a11yRepo = AccessibilityPrefsLocalRepository();

      await notifRepo.save(await notifRepo.load());
      await langRepo.save(const LanguagePrefs(Locale('en')));
      await a11yRepo.save(await a11yRepo.load());

      final reloadedNotif = await notifRepo.load();
      final reloadedLang = await langRepo.load();
      final reloadedA11y = await a11yRepo.load();

      expect(reloadedNotif.notificationsEnabled, isTrue);
      expect(reloadedLang.locale?.languageCode, 'en');
      expect(reloadedA11y.hapticsEnabled, isTrue);
    });

    test('contaminated keys do not crash loaders', () async {
      SharedPreferences.setMockInitialValues({
        'settings.notifications.v1': '{bad', // still string, but corrupt JSON
        'settings.language.v1': '{bad',
        'settings.accessibility.v1': '{bad',
      });

      final notifRepo = NotificationPrefsLocalRepository();
      final langRepo = LanguagePrefsLocalRepository();
      final a11yRepo = AccessibilityPrefsLocalRepository();

      final notif = await notifRepo.load();
      final lang = await langRepo.load();
      final a11y = await a11yRepo.load();

      expect(notif.notificationsEnabled, isTrue);
      expect(lang.locale, isNull);
      expect(a11y.hapticsEnabled, isTrue);
    });
  });
}
