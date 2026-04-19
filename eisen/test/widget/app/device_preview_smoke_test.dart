import 'package:device_preview/device_preview.dart';
import 'package:eisen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('EisenApp inicia dentro de DevicePreview sin excepciones',
      (tester) async {
    await tester.pumpWidget(
      DevicePreview(
        enabled: true,
        builder: (_) => const ProviderScope(
          child: EisenApp(),
        ),
      ),
    );

    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
