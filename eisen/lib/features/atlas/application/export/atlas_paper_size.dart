import 'package:pdf/pdf.dart';

enum AtlasPaperSize {
  letter,
  a4,
  legal,
  a3,
  archA,
  archB,
  archC,
  archD,
  archE,
  archE1,
  custom,
}

enum AtlasPaperOrientation {
  portrait,
  landscape,
}

String atlasPaperSizeLabel(AtlasPaperSize size) {
  return switch (size) {
    AtlasPaperSize.letter => 'Carta · 8.5" × 11"',
    AtlasPaperSize.a4 => 'A4 · 210 × 297 mm',
    AtlasPaperSize.legal => 'Legal / Oficio · 8.5" × 14"',
    AtlasPaperSize.a3 => 'A3 · 297 × 420 mm',
    AtlasPaperSize.archA => 'ARCH A · 9" × 12"',
    AtlasPaperSize.archB => 'ARCH B · 12" × 18"',
    AtlasPaperSize.archC => 'ARCH C · 18" × 24"',
    AtlasPaperSize.archD => 'ARCH D · 24" × 36"',
    AtlasPaperSize.archE => 'ARCH E · 36" × 48"',
    AtlasPaperSize.archE1 => 'ARCH E1 · 30" × 42"',
    AtlasPaperSize.custom => 'Personalizado',
  };
}

PdfPageFormat atlasPdfPageFormat(
  AtlasPaperSize size, {
  required AtlasPaperOrientation orientation,
  double? customWidthInches,
  double? customHeightInches,
}) {
  PdfPageFormat format = switch (size) {
    AtlasPaperSize.letter => PdfPageFormat.letter,
    AtlasPaperSize.a4 => PdfPageFormat.a4,
    AtlasPaperSize.legal => PdfPageFormat.legal,
    AtlasPaperSize.a3 => PdfPageFormat.a3,
    AtlasPaperSize.archA => PdfPageFormat(9 * PdfPageFormat.inch, 12 * PdfPageFormat.inch),
    AtlasPaperSize.archB => PdfPageFormat(12 * PdfPageFormat.inch, 18 * PdfPageFormat.inch),
    AtlasPaperSize.archC => PdfPageFormat(18 * PdfPageFormat.inch, 24 * PdfPageFormat.inch),
    AtlasPaperSize.archD => PdfPageFormat(24 * PdfPageFormat.inch, 36 * PdfPageFormat.inch),
    AtlasPaperSize.archE => PdfPageFormat(36 * PdfPageFormat.inch, 48 * PdfPageFormat.inch),
    AtlasPaperSize.archE1 => PdfPageFormat(30 * PdfPageFormat.inch, 42 * PdfPageFormat.inch),
    AtlasPaperSize.custom => customWidthInches != null && customHeightInches != null
        ? PdfPageFormat(
            customWidthInches * PdfPageFormat.inch,
            customHeightInches * PdfPageFormat.inch,
          )
        : PdfPageFormat.letter,
  };

  return switch (orientation) {
    AtlasPaperOrientation.landscape => format.landscape,
    AtlasPaperOrientation.portrait => format.portrait,
  };
}

double marginForPaperSize(AtlasPaperSize size) {
  return switch (size) {
    AtlasPaperSize.letter || AtlasPaperSize.a4 || AtlasPaperSize.legal => 24,
    AtlasPaperSize.a3 || AtlasPaperSize.archA || AtlasPaperSize.archB => 30,
    AtlasPaperSize.archC ||
    AtlasPaperSize.archD ||
    AtlasPaperSize.archE ||
    AtlasPaperSize.archE1 ||
    AtlasPaperSize.custom =>
      36,
  };
}
