import 'package:eisen/features/focus/presentation/pages/focus_dashboard_page.dart';
import 'package:eisen/features/settings/presentation/pages/settings_screen.dart';
import 'package:eisen/features/stats/presentation/pages/stats_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('páginas principales hospedadas por shell montan sin excepciones',
      (tester) async {
    await _pumpHostedPage(
      tester,
      const StatsPage(useShellNavigation: true),
    );
    expect(tester.takeException(), isNull);

    await _pumpHostedPage(
      tester,
      const FocusDashboardPage(useShellNavigation: true),
    );
    expect(tester.takeException(), isNull);

    await _pumpHostedPage(
      tester,
      const SettingsScreen(useShellNavigation: true),
      size: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHostedPage(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1024, 768),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}
