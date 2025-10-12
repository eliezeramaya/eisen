import 'package:eisenhower_treemap_flutter/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Matrix app smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EisenApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    // Expect to find toolbar actions
    expect(find.byIcon(Icons.add), findsWidgets);
  });
}

