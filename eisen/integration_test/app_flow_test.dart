import 'package:eisen/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App flow E2E', () {
    testWidgets('crea una tarea y la muestra en matriz/lista', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Abre el sheet de creación (asumiendo botón con tooltip o icono de add)
      final addFab = find.byIcon(Icons.add);
      expect(addFab, findsOneWidget);
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      // Llena título de tarea
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Tarea E2E');

      // Guarda/crea la tarea (asumimos botón de texto "Guardar" o similar)
      final saveButton = find.textContaining('Guardar').first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verifica que la tarea aparece en la pantalla
      expect(find.text('Tarea E2E'), findsWidgets);
    });
  });
}
