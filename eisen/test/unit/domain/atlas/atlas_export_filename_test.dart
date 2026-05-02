import 'package:eisen/features/atlas/application/atlas_export_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera eisen-atlas-YYYY-MM-DD.png', () {
    final filename = atlasExportFilename(
      date: DateTime(2026, 5, 2, 14, 30),
    );

    expect(filename, 'eisen-atlas-2026-05-02.png');
  });

  test('puede incluir hora para evitar colisiones', () {
    final filename = atlasExportFilename(
      date: DateTime(2026, 5, 2, 14, 30),
      includeTime: true,
    );

    expect(filename, 'eisen-atlas-2026-05-02-1430.png');
  });

  test('no contiene caracteres inválidos para nombres de archivo', () {
    final filenames = [
      atlasExportFilename(date: DateTime(2026, 5, 2)),
      atlasExportFilename(
        date: DateTime(2026, 5, 2, 14, 30),
        includeTime: true,
      ),
    ];
    final invalidCharacters = RegExp(r'[\\/:*?"<>|]');

    for (final filename in filenames) {
      expect(filename, isNot(contains(invalidCharacters)));
    }
  });
}
