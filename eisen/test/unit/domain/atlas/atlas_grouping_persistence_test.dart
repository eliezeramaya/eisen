import 'dart:async';

import 'package:eisen/core/storage/local_storage_keys.dart';
import 'package:eisen/features/atlas/application/atlas_providers.dart';
import 'package:eisen/features/atlas/data/atlas_grouping_prefs.dart';
import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('guarda y recupera grouping', () async {
    const prefs = AtlasGroupingPrefs();

    await prefs.save(AtlasGrouping.quadrant);

    expect(await prefs.load(), AtlasGrouping.quadrant);
  });

  test('fallback a category si valor inválido', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageKeys.atlasGrouping: 'unknown',
    });

    expect(await const AtlasGroupingPrefs().load(), AtlasGrouping.category);
  });

  test('atlasGroupingProvider carga y persiste cambios', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageKeys.atlasGrouping: AtlasGrouping.energy.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final loaded = Completer<AtlasGrouping>();
    container.listen<AtlasGrouping>(
      atlasGroupingProvider,
      (_, next) {
        if (next == AtlasGrouping.energy && !loaded.isCompleted) {
          loaded.complete(next);
        }
      },
      fireImmediately: true,
    );

    expect(container.read(atlasGroupingProvider), AtlasGrouping.category);
    expect(
      await loaded.future.timeout(const Duration(seconds: 1)),
      AtlasGrouping.energy,
    );

    container.read(atlasGroupingProvider.notifier).update(AtlasGrouping.kind);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(LocalStorageKeys.atlasGrouping),
      AtlasGrouping.kind.name,
    );
  });
}
