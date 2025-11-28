import 'package:eisen/features/filters/presentation/widgets/category_filters_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renderiza botón de gestionar filtros y chips según categorías',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CategoryFiltersBar()))));
    expect(find.byKey(const Key('btn_manage_filters')), findsOneWidget);
  });
}
