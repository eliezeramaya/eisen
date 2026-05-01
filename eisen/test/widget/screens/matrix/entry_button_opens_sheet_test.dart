import 'package:eisen/features/eisen_matrix/presentation/pages/matrix_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MatrixPage hospedada por shell monta en mobile sin excepciones',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MatrixPage(useShellNavigation: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('MatrixPage standalone monta sin excepciones', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MatrixPage())));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
