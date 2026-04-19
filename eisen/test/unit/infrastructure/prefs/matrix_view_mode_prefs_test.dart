import 'dart:convert';

import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MatrixController does not override topK on first load without view prefs', () async {
    // Arrange: simulate existing UI prefs with a non-default topKPerQuadrant.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'eisen.ui.v1':
          jsonEncode(const UiPrefsData(topKPerQuadrant: 33).toJson()),
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Act: build controller (which triggers _init on UiPrefsController)
    final controller = container.read(matrixControllerProvider.notifier);
    await controller.load();

    // Assert: existing topKPerQuadrant is preserved because no matrix view prefs exist yet.
    final uiPrefs = await UiPrefs().load();
    expect(uiPrefs.topKPerQuadrant, 33);
  });
}
