import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/report.dart';

enum StatsExportFormat { json, csv, pdfLike }

class StatsExportResult {
  const StatsExportResult({
    required this.format,
    required this.content,
    this.filePath,
  });

  final StatsExportFormat format;
  final String content;
  final String? filePath;
}

/// Helper to save stats exports to a temporary file and return the path.
class StatsExporter {
  Future<StatsExportResult> export(
    StatsExportBundle bundle,
    StatsExportFormat format,
  ) async {
    final content = switch (format) {
      StatsExportFormat.json => bundle.json,
      StatsExportFormat.csv => bundle.csv,
      StatsExportFormat.pdfLike => bundle.printable,
    };

    if (kIsWeb) {
      // Web: return content only so UI can present copyable text.
      return StatsExportResult(format: format, content: content);
    }

    final dir = await getTemporaryDirectory();
    final ext = switch (format) {
      StatsExportFormat.json => 'json',
      StatsExportFormat.csv => 'csv',
      StatsExportFormat.pdfLike => 'txt', // printable text; viewer-friendly
    };
    final file = File(
        '${dir.path}/eisen_stats_${bundle.report.range.start.millisecondsSinceEpoch}_$ext.$ext');
    await file.writeAsString(content);

    return StatsExportResult(
      format: format,
      content: content,
      filePath: file.path,
    );
  }
}
