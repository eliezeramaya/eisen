import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/filters/filters_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('default false', () async {
    expect(await const ShowArchivedPrefs().load(), isFalse);
  });

  test('guarda true y recupera true', () async {
    const prefs = ShowArchivedPrefs();

    await prefs.save(true);

    expect(await prefs.load(), isTrue);
    final raw = await SharedPreferences.getInstance();
    expect(raw.getBool(LocalStorageKeys.filtersShowArchived), isTrue);
  });
}
