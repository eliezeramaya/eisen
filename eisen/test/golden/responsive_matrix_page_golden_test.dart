import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:eisen/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ensures binding is initialized for golden tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatrixPage responsive goldens', () {
    // Note: We exclude semantics at the widget level for goldens to avoid
    // invisible semantics assertions and focus purely on visual diffs.
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });
    final scenarios = <String, Size>{
      'xs-390x844': const Size(390, 844), // iPhone 13/14
      'sm-800x600': const Size(800, 600), // small landscape/tablet
      'md-1024x768': const Size(1024, 768),
      'lg-1366x900': const Size(1366, 900),
      'xl-1600x1024': const Size(1600, 1024),
    };

    Future<void> _pumpApp(WidgetTester tester, Size size, double textScale) async {
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
      testGoldens('layout_${entry.key}_text1.0', (tester) async {
        await _pumpApp(tester, entry.value, 1.0);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_0');
      });

      testGoldens('layout_${entry.key}_text1.3', (tester) async {
        await _pumpApp(tester, entry.value, 1.3);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_3');
      });

      testGoldens('layout_${entry.key}_text1.6', (tester) async {
        await _pumpApp(tester, entry.value, 1.6);
        await screenMatchesGolden(tester, 'matrix_${entry.key}_ts1_6');
      });
    }
  });
}
