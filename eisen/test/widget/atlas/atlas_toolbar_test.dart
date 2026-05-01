import 'package:eisen/features/atlas/presentation/widgets/atlas_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtlasToolbar muestra selector de agrupación', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AtlasToolbar(),
          ),
        ),
      ),
    );

    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Agrupar por'), findsWidgets);
  });
}
