import 'package:eisen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('home screen golden', (tester) async {
    const size = Size(1280, 800);

    await tester.pumpWidgetBuilder(
      const ExcludeSemantics(child: ProviderScope(child: EisenApp())),
      surfaceSize: size,
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });
}
