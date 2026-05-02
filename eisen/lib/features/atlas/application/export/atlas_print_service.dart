import 'dart:typed_data';

import 'package:eisen/features/atlas/application/export/atlas_pdf_data.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_report_service.dart';
import 'package:printing/printing.dart';

/// Thin wrapper around [Printing] that builds and shares/prints a PDF.
class AtlasPrintService {
  const AtlasPrintService({
    this.reportService = const AtlasPdfReportService(),
  });

  final AtlasPdfReportService reportService;

  Future<Uint8List> buildPdfBytes({
    required AtlasPdfData data,
    required AtlasPdfOptions options,
  }) {
    return reportService.buildPdf(data: data, options: options);
  }

  /// Returns true if printing is available on the current platform.
  Future<bool> isPrintingAvailable() {
    return Printing.info().then((info) => info.canPrint);
  }
}
