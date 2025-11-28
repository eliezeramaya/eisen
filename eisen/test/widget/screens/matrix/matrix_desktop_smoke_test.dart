import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/ui/matrix/matrix_desktop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatrixDesktop', () {
    testWidgets('muestra encabezados y tareas por cuadrante', (tester) async {
      final q1Task = Task(
        id: 'q1',
        title: 'Responder incidente',
        quadrant: Quadrant.q1,
        priority: 8,
        minutes: 30,
      );
      final q2Task = Task(
        id: 'q2',
        title: 'Planificar sprint',
        quadrant: Quadrant.q2,
        priority: 6,
        minutes: 45,
      );
      final q3Task = Task(
        id: 'q3',
        title: 'Llamada imprevista',
        quadrant: Quadrant.q3,
        priority: 4,
        minutes: 20,
      );
      final q4Task = Task(
        id: 'q4',
        title: 'Limpiar correo',
        quadrant: Quadrant.q4,
        priority: 2,
        minutes: 15,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MatrixDesktop(
                q1: [q1Task],
                q2: [q2Task],
                q3: [q3Task],
                q4: [q4Task],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Q1 (1)'), findsOneWidget);
      expect(find.text('Q2 (1)'), findsOneWidget);
      expect(find.text('Q3 (1)'), findsOneWidget);
      expect(find.text('Q4 (1)'), findsOneWidget);

      expect(find.text('Responder incidente'), findsOneWidget);
      expect(find.text('Planificar sprint'), findsOneWidget);
      expect(find.text('Llamada imprevista'), findsOneWidget);
      expect(find.text('Limpiar correo'), findsOneWidget);
    });
  });
}
