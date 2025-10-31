import 'package:device_preview/device_preview.dart';
import 'package:eisen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatrixPage goldens (requested sizes)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    final scenarios = <String, Size>{
      'xs-320x640': const Size(320, 640),
      'sm-600x1024': const Size(600, 1024),
      'md-1024x768': const Size(1024, 768),
      'lg-1440x900': const Size(1440, 900),
    };

    Future<void> pumpApp(WidgetTester tester, Size size, double textScale) async {
      await tester.pumpWidgetBuilder(
        const ExcludeSemantics(child: ProviderScope(child: EisenApp())),
        surfaceSize: size,
        wrapper: (child) => MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
          child: DevicePreview(enabled: false, builder: (_) => child),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    for (final entry in scenarios.entries) {
      testGoldens('matrix_${entry.key}_ts1_0', (tester) async {
        await pumpApp(tester, entry.value, 1.0);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_0');
      }, skip: true); // Scaffolded: remove skip after adding baseline images

      testGoldens('matrix_${entry.key}_ts1_3', (tester) async {
        await pumpApp(tester, entry.value, 1.3);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_3');
      }, skip: true);

      testGoldens('matrix_${entry.key}_ts1_6', (tester) async {
        await pumpApp(tester, entry.value, 1.6);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_6');
      }, skip: true);
    }
  });
}

