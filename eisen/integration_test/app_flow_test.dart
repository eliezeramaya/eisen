import 'package:eisen/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('App flow E2E', () {
    testWidgets('crea una tarea y la muestra en matriz/lista', (tester) async {
      app.main();
      await tester.pump();
      await _pumpUntil(
        tester,
        () => _entryFinder().evaluate().isNotEmpty,
        reason: 'Expected Entry/Entrada action to appear on the main screen',
      );

      final entryButton = _entryFinder();
      expect(entryButton, findsOneWidget);
      await tester.tap(entryButton);
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('Título').evaluate().isNotEmpty,
        reason: 'Expected AddTaskSheet to appear with title field',
      );

      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Tarea E2E');
      await tester.pump(const Duration(milliseconds: 200));

      final saveButton = find.text('Guardar').first;
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('Tarea E2E').evaluate().isNotEmpty,
        reason: 'Expected the created task to appear in the matrix',
      );

      expect(find.text('Tarea E2E'), findsWidgets);
    });
  });
}

Finder _entryFinder() {
  final entryEs = find.text('Entrada');
  final entryEn = find.text('Entry');
  if (entryEs.evaluate().isNotEmpty) {
    return entryEs.first;
  }
  if (entryEn.evaluate().isNotEmpty) {
    return entryEn.first;
  }

  final iconTooltipEs = find.byTooltip('Entrada');
  final iconTooltipEn = find.byTooltip('Entry');
  if (iconTooltipEs.evaluate().isNotEmpty) {
    return iconTooltipEs.first;
  }
  if (iconTooltipEn.evaluate().isNotEmpty) {
    return iconTooltipEn.first;
  }

  final entrySemEs = find.bySemanticsLabel('Entrada');
  final entrySemEn = find.bySemanticsLabel('Entry');
  if (entrySemEs.evaluate().isNotEmpty) {
    return entrySemEs.first;
  }
  if (entrySemEn.evaluate().isNotEmpty) {
    return entrySemEn.first;
  }

  return find.byType(FilledButton).first;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration step = const Duration(milliseconds: 250),
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }
  fail(reason);
}
