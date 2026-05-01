import 'package:eisen/core/responsive/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResponsiveScaffold renderiza y propaga selección por tamaño',
      (tester) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1366, 900),
    ]) {
      var selectedIndex = -1;
      await _pumpScaffold(
        tester,
        size,
        onDestinationSelected: (index) => selectedIndex = index,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Workspace'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.timer_outlined).last);
      await tester.pump();
      expect(selectedIndex, 1);
    }
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester,
  Size size, {
  required ValueChanged<int> onDestinationSelected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ResponsiveScaffold(
        currentIndex: 0,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          AppNavDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Matrix',
          ),
          AppNavDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
        ],
        body: const Center(child: Text('Workspace')),
      ),
    ),
  );
  await tester.pump();
}
