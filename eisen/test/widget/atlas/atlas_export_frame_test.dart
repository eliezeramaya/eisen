import 'package:eisen/features/atlas/presentation/widgets/atlas_export_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza child sin header por default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AtlasExportFrame(
            child: Text('Canvas exportable'),
          ),
        ),
      ),
    );

    expect(find.text('Canvas exportable'), findsOneWidget);
    expect(find.text('Atlas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('includeHeader=true muestra titulo, fecha y agrupacion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 420,
            child: AtlasExportFrame(
              includeHeader: true,
              title: 'Atlas',
              subtitle: 'Reporte visual',
              date: DateTime(2026, 5, 2),
              groupingLabel: 'Cuadrante',
              insights: const ['Día cargado'],
              child: const ColoredBox(
                color: Colors.blue,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Reporte visual'), findsOneWidget);
    expect(find.text('2026-05-02'), findsOneWidget);
    expect(find.text('Agrupación: Cuadrante'), findsOneWidget);
    expect(find.text('Día cargado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('includeHeader=true muestra metadata de reporte visual',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 460,
            child: AtlasExportFrame(
              includeHeader: true,
              title: 'Atlas',
              subtitle: 'Reporte visual de tareas',
              date: DateTime(2026, 5, 2),
              groupingLabel: 'Categoría',
              filtersLabel: 'Activos + archivadas',
              visibleTaskCount: 7,
              insights: const [
                '70% de tus tareas están en Trabajo',
                'Crecimiento tiene baja presencia',
              ],
              footerLabel: 'Eisen',
              child: const ColoredBox(
                color: Colors.blue,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Reporte visual de tareas'), findsOneWidget);
    expect(find.text('2026-05-02'), findsOneWidget);
    expect(find.text('Agrupación: Categoría'), findsOneWidget);
    expect(find.text('Filtros: Activos + archivadas'), findsOneWidget);
    expect(find.text('7 tareas visibles'), findsOneWidget);
    expect(find.text('70% de tus tareas están en Trabajo'), findsOneWidget);
    expect(find.text('Crecimiento tiene baja presencia'), findsOneWidget);
    expect(find.text('Eisen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metadata usa singular para una tarea visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 360,
            child: AtlasExportFrame(
              includeHeader: true,
              visibleTaskCount: 1,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 tarea visible'), findsOneWidget);
  });

  testWidgets('usa fondo del tema y monta en dark mode', (tester) async {
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AtlasExportFrame(
            includeHeader: true,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == theme.colorScheme.surface,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('aplica contraste base en light mode', (tester) async {
    final theme = ThemeData.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AtlasExportFrame(
            child: Row(
              children: [
                Icon(Icons.map_outlined),
                Text('Contenido exportable'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == theme.colorScheme.surface,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DefaultTextStyle &&
            widget.style.color == theme.colorScheme.onSurface,
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconTheme &&
            widget.data.color == theme.colorScheme.onSurface,
      ),
      findsWidgets,
    );
  });

  testWidgets('header usa colores legibles en dark mode', (tester) async {
    final theme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: SizedBox(
          width: 640,
          height: 420,
          child: AtlasExportFrame(
            includeHeader: true,
            title: 'Atlas',
            subtitle: 'Reporte visual',
            date: DateTime(2026, 5, 2),
            groupingLabel: 'Categoría',
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Atlas'));
    final subtitle = tester.widget<Text>(find.text('Reporte visual'));
    final date = tester.widget<Text>(find.text('2026-05-02'));

    expect(title.style?.color, theme.colorScheme.onSurface);
    expect(subtitle.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(date.style?.color, theme.colorScheme.onSurfaceVariant);
  });
}
