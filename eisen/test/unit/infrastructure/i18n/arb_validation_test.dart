import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('i18n ARB files validation', () {
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> esArb;
    late String l10nDir;

    setUpAll(() {
      // Find the l10n directory relative to the test file
      final testDir = Directory.current.path;
      l10nDir = path.join(testDir, 'l10n');

      // Load ARB files
      final enFile = File(path.join(l10nDir, 'app_en.arb'));
      final esFile = File(path.join(l10nDir, 'app_es.arb'));

      expect(enFile.existsSync(), isTrue,
          reason: 'app_en.arb must exist at $l10nDir');
      expect(esFile.existsSync(), isTrue,
          reason: 'app_es.arb must exist at $l10nDir');

      enArb = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      esArb = jsonDecode(esFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('app_en.arb is valid JSON', () {
      expect(enArb, isNotEmpty);
    });

    test('app_es.arb is valid JSON', () {
      expect(esArb, isNotEmpty);
    });

    test('no orphaned keys in Spanish (keys not in English)', () {
      // Filter out metadata keys (start with @)
      final enKeys = enArb.keys.where((k) => !k.startsWith('@')).toSet();
      final esKeys = esArb.keys.where((k) => !k.startsWith('@')).toSet();

      final orphaned = esKeys.difference(enKeys);

      expect(
        orphaned,
        isEmpty,
        reason: 'Spanish ARB contains keys not in English: $orphaned\n'
            'Remove these keys or add them to app_en.arb',
      );
    });

    test('no missing keys in Spanish (keys in English but not Spanish)', () {
      // Filter out metadata keys (start with @)
      final enKeys = enArb.keys.where((k) => !k.startsWith('@')).toSet();
      final esKeys = esArb.keys.where((k) => !k.startsWith('@')).toSet();

      final missing = enKeys.difference(esKeys);

      expect(
        missing,
        isEmpty,
        reason: 'Spanish ARB is missing keys from English: $missing\n'
            'Add translations for these keys to app_es.arb',
      );
    });

    test('both ARB files have same number of translation keys', () {
      final enKeyCount =
          enArb.keys.where((k) => !k.startsWith('@')).length;
      final esKeyCount =
          esArb.keys.where((k) => !k.startsWith('@')).length;

      expect(
        esKeyCount,
        enKeyCount,
        reason: 'English has $enKeyCount keys, Spanish has $esKeyCount keys',
      );
    });

    test('all keys follow naming convention (camelCase)', () {
      final allKeys = {...enArb.keys, ...esArb.keys}
          .where((k) => !k.startsWith('@'));

      final invalidKeys = allKeys.where((key) {
        // camelCase: starts with lowercase, no underscores/hyphens
        final camelCasePattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');
        return !camelCasePattern.hasMatch(key);
      }).toList();

      expect(
        invalidKeys,
        isEmpty,
        reason: 'Keys should use camelCase: $invalidKeys',
      );
    });

    test('no empty translation values', () {
      final emptyInEn = enArb.entries
          .where((e) => !e.key.startsWith('@') && (e.value as String).isEmpty)
          .map((e) => e.key)
          .toList();

      final emptyInEs = esArb.entries
          .where((e) => !e.key.startsWith('@') && (e.value as String).isEmpty)
          .map((e) => e.key)
          .toList();

      expect(emptyInEn, isEmpty,
          reason: 'English ARB has empty values for: $emptyInEn');
      expect(emptyInEs, isEmpty,
          reason: 'Spanish ARB has empty values for: $emptyInEs');
    });

    test('placeholder syntax is consistent between languages', () {
      // Find keys with placeholders in English
      final enPlaceholders = <String, Set<String>>{};

      for (final entry in enArb.entries) {
        if (entry.key.startsWith('@')) continue;
        final value = entry.value as String;
        final matches = RegExp(r'\{(\w+)\}').allMatches(value);
        if (matches.isNotEmpty) {
          enPlaceholders[entry.key] =
              matches.map((m) => m.group(1)!).toSet();
        }
      }

      // Verify Spanish has same placeholders
      final errors = <String>[];
      for (final key in enPlaceholders.keys) {
        if (!esArb.containsKey(key)) continue;

        final esValue = esArb[key] as String;
        final esMatches = RegExp(r'\{(\w+)\}').allMatches(esValue);
        final esPlaceholderSet = esMatches.map((m) => m.group(1)!).toSet();

        final enPlaceholderSet = enPlaceholders[key]!;

        if (!esPlaceholderSet.containsAll(enPlaceholderSet) ||
            !enPlaceholderSet.containsAll(esPlaceholderSet)) {
          errors.add(
            '$key: EN has $enPlaceholderSet, ES has $esPlaceholderSet',
          );
        }
      }

      expect(errors, isEmpty,
          reason: 'Placeholder mismatch:\n${errors.join('\n')}');
    });

    test('untranslated.txt exists for tracking', () {
      final untranslatedFile = File(path.join(l10nDir, 'untranslated.txt'));
      expect(untranslatedFile.existsSync(), isTrue,
          reason: 'untranslated.txt should exist for manual tracking');
    });

    test('ARB files are properly formatted JSON', () {
      // Re-encode and check it matches (proper formatting)
      final enFormatted = const JsonEncoder.withIndent('  ').convert(enArb);
      final esFormatted = const JsonEncoder.withIndent('  ').convert(esArb);

      final enFile = File(path.join(l10nDir, 'app_en.arb'));
      final esFile = File(path.join(l10nDir, 'app_es.arb'));

      final enContent = enFile.readAsStringSync().trim();
      final esContent = esFile.readAsStringSync().trim();

      expect(enContent, enFormatted,
          reason: 'app_en.arb should be formatted with 2-space indent');
      expect(esContent, esFormatted,
          reason: 'app_es.arb should be formatted with 2-space indent');
    });
  });

  group('i18n code generation verification', () {
    test('generated l10n files should be up to date', () {
      // This test verifies that gen-l10n has been run
      // Files are generated to lib/l10n per l10n.yaml configuration

      final genDir = Directory(
        path.join(Directory.current.path, 'lib', 'l10n'),
      );

      // This directory should exist after running flutter gen-l10n
      if (genDir.existsSync()) {
        final appLocalizations = File(path.join(genDir.path, 'app_localizations.dart'));
        expect(appLocalizations.existsSync(), isTrue,
            reason: 'Generated app_localizations.dart should exist. Run: flutter gen-l10n');
      } else {
        // Directory doesn't exist - gen-l10n needs to be run
        fail('lib/l10n directory not found. Run: flutter gen-l10n');
      }
    });
  });
}
