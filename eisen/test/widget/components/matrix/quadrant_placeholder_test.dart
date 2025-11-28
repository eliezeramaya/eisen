import 'package:eisen/features/eisen_matrix/presentation/widgets/quadrant_empty_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuadrantEmptyPlaceholder renders title and hint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const QuadrantEmptyPlaceholder(
            title: 'Q1 · Urgente e Importante',
            hint: 'No tienes tareas aquí. Usa “Entrada”.',
          ),
        ),
      ),
    );

    expect(find.textContaining('Q1'), findsOneWidget);
    expect(find.textContaining('No tienes tareas'), findsOneWidget);
  });
}
