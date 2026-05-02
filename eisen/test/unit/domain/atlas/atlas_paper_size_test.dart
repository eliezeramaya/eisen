import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('atlasPdfPageFormat — ARCH sizes', () {
    const portrait = AtlasPaperOrientation.portrait;
    const landscape = AtlasPaperOrientation.landscape;

    test('ARCH A is 9 × 12 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archA, orientation: portrait);
      expect(f.width, closeTo(9 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(12 * PdfPageFormat.inch, 0.1));
    });

    test('ARCH B is 12 × 18 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archB, orientation: portrait);
      expect(f.width, closeTo(12 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(18 * PdfPageFormat.inch, 0.1));
    });

    test('ARCH C is 18 × 24 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archC, orientation: portrait);
      expect(f.width, closeTo(18 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(24 * PdfPageFormat.inch, 0.1));
    });

    test('ARCH D is 24 × 36 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archD, orientation: portrait);
      expect(f.width, closeTo(24 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(36 * PdfPageFormat.inch, 0.1));
    });

    test('ARCH E is 36 × 48 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archE, orientation: portrait);
      expect(f.width, closeTo(36 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(48 * PdfPageFormat.inch, 0.1));
    });

    test('ARCH E1 is 30 × 42 inches in portrait', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.archE1, orientation: portrait);
      expect(f.width, closeTo(30 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(42 * PdfPageFormat.inch, 0.1));
    });

    test('landscape inverts width and height for ARCH B', () {
      final portrait = atlasPdfPageFormat(AtlasPaperSize.archB, orientation: AtlasPaperOrientation.portrait);
      final land = atlasPdfPageFormat(AtlasPaperSize.archB, orientation: landscape);
      expect(land.width, closeTo(portrait.height, 0.1));
      expect(land.height, closeTo(portrait.width, 0.1));
    });

    test('custom without values falls back to letter', () {
      final f = atlasPdfPageFormat(AtlasPaperSize.custom, orientation: portrait);
      expect(f.width, closeTo(PdfPageFormat.letter.width, 0.1));
      expect(f.height, closeTo(PdfPageFormat.letter.height, 0.1));
    });

    test('custom with explicit inches uses those dimensions', () {
      final f = atlasPdfPageFormat(
        AtlasPaperSize.custom,
        orientation: portrait,
        customWidthInches: 20,
        customHeightInches: 30,
      );
      expect(f.width, closeTo(20 * PdfPageFormat.inch, 0.1));
      expect(f.height, closeTo(30 * PdfPageFormat.inch, 0.1));
    });
  });

  group('marginForPaperSize', () {
    test('letter/a4/legal → 24', () {
      expect(marginForPaperSize(AtlasPaperSize.letter), 24);
      expect(marginForPaperSize(AtlasPaperSize.a4), 24);
      expect(marginForPaperSize(AtlasPaperSize.legal), 24);
    });

    test('a3/archA/archB → 30', () {
      expect(marginForPaperSize(AtlasPaperSize.a3), 30);
      expect(marginForPaperSize(AtlasPaperSize.archA), 30);
      expect(marginForPaperSize(AtlasPaperSize.archB), 30);
    });

    test('archC/archD/archE/archE1 → 36', () {
      expect(marginForPaperSize(AtlasPaperSize.archC), 36);
      expect(marginForPaperSize(AtlasPaperSize.archD), 36);
      expect(marginForPaperSize(AtlasPaperSize.archE), 36);
      expect(marginForPaperSize(AtlasPaperSize.archE1), 36);
    });
  });

  group('atlasPaperSizeLabel', () {
    test('archB label contains ARCH B', () {
      expect(atlasPaperSizeLabel(AtlasPaperSize.archB), contains('ARCH B'));
    });

    test('letter label contains Carta', () {
      expect(atlasPaperSizeLabel(AtlasPaperSize.letter), contains('Carta'));
    });
  });
}
