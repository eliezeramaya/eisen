import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('AtlasToolbar monta sin excepciones', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AtlasToolbar(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile oculta microcopy y muestra menú de acciones',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 720)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(390),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
        find.text('Visualiza todas tus tareas en un solo mapa'), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('desktop muestra microcopy y acciones inline', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(1280),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Visualiza todas tus tareas en un solo mapa'),
        findsOneWidget);
    expect(find.text('Mostrar archivadas'), findsOneWidget);
  });

  testWidgets('desktop muestra acción exportar inline', (tester) async {
    var exported = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(1280),
                onExportPng: () => exported = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Exportar PNG'), findsOneWidget);
    await tester.tap(find.text('Exportar PNG'));
    await tester.pump();

    expect(exported, isTrue);
  });

  testWidgets('desktop deshabilita exportar mientras está exportando',
      (tester) async {
    var exported = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(1280),
                isExporting: true,
                onExportPng: () => exported = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Exportando'), findsOneWidget);
    await tester.tap(find.text('Exportando'));
    await tester.pump();

    expect(exported, isFalse);
  });

  testWidgets('mobile ubica acción exportar en menú Más', (tester) async {
    var exported = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 720)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(390),
                onExportPng: () => exported = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Exportar PNG'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Exportar PNG'), findsOneWidget);
    await tester.tap(find.text('Exportar PNG'));
    await tester.pumpAndSettle();

    expect(exported, isTrue);
  });

  testWidgets('mobile deshabilita exportar en menú Más durante exportación',
      (tester) async {
    var exported = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 720)),
            child: Scaffold(
              body: AtlasToolbar(
                config: atlasResponsiveConfigForWidth(390),
                isExporting: true,
                onExportPng: () => exported = true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Exportando'), findsOneWidget);
    await tester.tap(find.text('Exportando'), warnIfMissed: false);
    await tester.pump();

    expect(exported, isFalse);
  });
}
