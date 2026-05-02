import 'package:eisen/features/atlas/application/export/atlas_pdf_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAtlasPdfFilename', () {
    final date = DateTime(2026, 5, 2, 14, 30);

    test('generates eisen-atlas-YYYY-MM-DD.pdf without time', () {
      expect(
        buildAtlasPdfFilename(date: date),
        'eisen-atlas-2026-05-02.pdf',
      );
    });

    test('includes HHmm when includeTime is true', () {
      expect(
        buildAtlasPdfFilename(date: date, includeTime: true),
        'eisen-atlas-2026-05-02-1430.pdf',
      );
    });

    test('pads single-digit month and day with zeros', () {
      final d = DateTime(2026, 1, 3);
      expect(
        buildAtlasPdfFilename(date: d),
        'eisen-atlas-2026-01-03.pdf',
      );
    });

    test('pads single-digit hour and minute', () {
      final d = DateTime(2026, 1, 3, 9, 5);
      expect(
        buildAtlasPdfFilename(date: d, includeTime: true),
        'eisen-atlas-2026-01-03-0905.pdf',
      );
    });

    test('filename has no invalid path characters', () {
      final filename = buildAtlasPdfFilename(date: date, includeTime: true);
      expect(filename, isNot(contains('/')));
      expect(filename, isNot(contains('\\')));
      expect(filename, isNot(contains(':')));
      expect(filename, isNot(contains('*')));
      expect(filename, isNot(contains('?')));
    });

    test('extension is .pdf', () {
      expect(buildAtlasPdfFilename(date: date), endsWith('.pdf'));
    });

    test('filename is lowercase', () {
      final filename = buildAtlasPdfFilename(date: date);
      expect(filename, filename.toLowerCase());
    });
  });
}
