import 'dart:typed_data';

import 'package:eisen/features/atlas/application/atlas_export_service.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_empty_state.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_export_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ratios de exportación quedan definidos para calidad futura', () {
    expect(AtlasExportPixelRatio.fast, 2.0);
    expect(AtlasExportPixelRatio.standard, 3.0);
    expect(AtlasExportPixelRatio.high, 4.0);
    expect(AtlasExportPixelRatio.min, 1.0);
    expect(AtlasExportPixelRatio.max, AtlasExportPixelRatio.high);
  });

  testWidgets('exportBoundaryToPng genera bytes PNG no vacíos', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: 120,
                height: 80,
                color: Colors.blue,
                alignment: Alignment.center,
                child: const Text('Atlas'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
        pixelRatio: AtlasExportPixelRatio.standard,
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(_startsWithPngSignature(bytes), isTrue);
  });

  testWidgets('exportBoundaryToPng no crashea con widget simple vacío',
      (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 1, height: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
        pixelRatio: AtlasExportPixelRatio.min,
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(_startsWithPngSignature(bytes), isTrue);
  });

  testWidgets('exportBoundaryToPng no crashea con Atlas sin tareas',
      (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(
            width: 320,
            height: 220,
            child: AtlasExportFrame(
              includeHeader: true,
              title: 'Atlas',
              visibleTaskCount: 0,
              child: AtlasEmptyState(kind: AtlasEmptyStateKind.noTasks),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
        pixelRatio: AtlasExportPixelRatio.standard,
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(_startsWithPngSignature(bytes), isTrue);
  });

  testWidgets('exportBoundaryToPng falla con error controlado sin context',
      (tester) async {
    final boundaryKey = GlobalKey();

    expect(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
      ),
      throwsA(isA<AtlasExportException>()),
    );
  });

  testWidgets('exportBoundaryToPng falla si el key no apunta a RepaintBoundary',
      (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          key: boundaryKey,
          width: 24,
          height: 24,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
      ),
      throwsA(
        isA<AtlasExportException>().having(
          (error) => error.message,
          'message',
          contains('RepaintBoundary'),
        ),
      ),
    );
  });

  testWidgets('exportBoundaryToPng soporta ratio alto 4.0', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 24, height: 24),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(
      () => const AtlasExportService().exportBoundaryToPng(
        repaintBoundaryKey: boundaryKey,
        pixelRatio: AtlasExportPixelRatio.high,
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes!, isNotEmpty);
    expect(_startsWithPngSignature(bytes), isTrue);
  });

  testWidgets('exportBoundaryToPng rechaza ratio inválido con error controlado',
      (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 24, height: 24),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final value in [0.0, -1.0, double.nan, double.infinity, 4.1]) {
      expect(
        () => const AtlasExportService().exportBoundaryToPng(
          repaintBoundaryKey: boundaryKey,
          pixelRatio: value,
        ),
        throwsA(isA<AtlasExportException>()),
        reason: 'pixelRatio=$value debe fallar de forma controlada',
      );
    }
  });
}

bool _startsWithPngSignature(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}
