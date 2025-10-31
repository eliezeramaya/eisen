import 'package:eisen/core/services/ui_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UiPrefs minimal default is false and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ui = UiPrefs();
    final loaded = await ui.load();
    expect(loaded.minimal, isFalse);

    final updated = loaded.copyWith(minimal: true, themeMode: ThemeMode.dark);
    await ui.save(updated);
    final loaded2 = await ui.load();
    expect(loaded2.minimal, isTrue);
    expect(loaded2.themeMode, ThemeMode.dark);
  });
}
