import 'package:eisen/features/settings/data/language_prefs_repository.dart';
import 'package:eisen/features/settings/domain/language_controller.dart';
import 'package:eisen/features/settings/domain/language_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LanguageController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults when no stored prefs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await container.read(languageControllerProvider.future);
      expect(prefs.locale, isNull);
    });

    test('persists and reloads locale', () async {
      final repo = LanguagePrefsLocalRepository();
      await repo.save(const LanguagePrefs(Locale('es')));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final prefs = await container.read(languageControllerProvider.future);
      expect(prefs.locale?.languageCode, 'es');
    });

    test('falls back to null when stored data is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        'settings.language.v1': '{broken json',
      });
      final repo = LanguagePrefsLocalRepository();
      final loaded = await repo.load();
      expect(loaded.locale, isNull);
    });

    test('setLocale saves preference', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(languageControllerProvider.notifier)
          .setLocale(const Locale('en'));
      final prefs = await container.read(languageControllerProvider.future);
      expect(prefs.locale?.languageCode, 'en');
    });
  });
}
