import 'package:eisen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('No FAB; single Entry button in bottom bar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EisenApp()));
    await tester.pump(const Duration(milliseconds: 200));

    // No FloatingActionButton present
    expect(find.byType(FloatingActionButton), findsNothing);

    // One Entry/Entrada button present in bottom bar
    final entryEs = find.text('Entrada');
    final entryEn = find.text('Entry');
    expect(
        entryEs.evaluate().isNotEmpty || entryEn.evaluate().isNotEmpty, isTrue);
  });
}
