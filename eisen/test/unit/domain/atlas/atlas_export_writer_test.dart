import 'dart:io';
import 'dart:typed_data';

import 'package:eisen/features/atlas/application/atlas_export_write_result.dart';
import 'package:eisen/features/atlas/application/atlas_export_writer_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writePng guarda PNG en documentos usando provider inyectado', () async {
    final directory = await Directory.systemTemp.createTemp(
      'eisen_atlas_export_writer_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1]);
    final result = await AtlasExportWriter(
      documentsDirectoryProvider: () async => directory,
    ).writePng(
      bytes: bytes,
      filename: 'eisen-atlas-2026-05-02.png',
    );

    final file = File(result.filePath!);
    expect(result.destination, AtlasExportWriteDestination.documents);
    expect(result.filename, 'eisen-atlas-2026-05-02.png');
    expect(result.bytes, bytes.length);
    expect(result.savedToFile, isTrue);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), bytes);
  });

  test('writePng crea el directorio si todavía no existe', () async {
    final parent = await Directory.systemTemp.createTemp(
      'eisen_atlas_export_writer_parent_',
    );
    final directory = Directory('${parent.path}${Platform.pathSeparator}atlas');
    addTearDown(() async {
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });

    await AtlasExportWriter(
      documentsDirectoryProvider: () async => directory,
    ).writePng(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'eisen-atlas-2026-05-02.png',
    );

    expect(await directory.exists(), isTrue);
  });

  test('writePng rechaza bytes vacíos y nombres inválidos', () async {
    const writer = AtlasExportWriter();

    expect(
      () => writer.writePng(
        bytes: Uint8List(0),
        filename: 'eisen-atlas-2026-05-02.png',
      ),
      throwsA(isA<AtlasExportWriteException>()),
    );

    for (final filename in [
      '',
      'atlas.txt',
      'folder/eisen-atlas.png',
      r'folder\eisen-atlas.png',
      'eisen:atlas.png',
    ]) {
      expect(
        () => writer.writePng(
          bytes: Uint8List.fromList([1]),
          filename: filename,
        ),
        throwsA(isA<AtlasExportWriteException>()),
        reason: filename,
      );
    }
  });
}
