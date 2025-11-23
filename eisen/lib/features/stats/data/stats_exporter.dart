import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/report.dart';

enum StatsExportFormat { json, csv, pdfLike }

enum StatsExportDestination {
  temporary, // Temp directory (default)
  documents, // User documents directory
  clipboard, // Copy to clipboard only
}

class StatsExportResult {
  const StatsExportResult({
    required this.format,
    required this.content,
    this.filePath,
    this.copiedToClipboard = false,
  });

  final StatsExportFormat format;
  final String content;
  final String? filePath;
  final bool copiedToClipboard;
}

/// Helper to save stats exports to file or clipboard
class StatsExporter {
  /// Export stats with configurable destination
  Future<StatsExportResult> export(
    StatsExportBundle bundle,
    StatsExportFormat format, {
    StatsExportDestination destination = StatsExportDestination.temporary,
  }) async {
    final content = switch (format) {
      StatsExportFormat.json => bundle.json,
      StatsExportFormat.csv => bundle.csv,
      StatsExportFormat.pdfLike => bundle.printable,
    };

    // Clipboard export
    if (destination == StatsExportDestination.clipboard) {
      await Clipboard.setData(ClipboardData(text: content));
      return StatsExportResult(
        format: format,
        content: content,
        copiedToClipboard: true,
      );
    }

    // Web: return content only so UI can present copyable text
    if (kIsWeb) {
      return StatsExportResult(format: format, content: content);
    }

    // File export
    final dir = await _getDirectory(destination);
    final ext = _getExtension(format);
    final filename = _generateFilename(bundle, ext);
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);

    debugPrint('Stats exported to: ${file.path}');

    return StatsExportResult(
      format: format,
      content: content,
      filePath: file.path,
    );
  }

  /// Export all formats at once
  Future<Map<StatsExportFormat, StatsExportResult>> exportAll(
    StatsExportBundle bundle, {
    StatsExportDestination destination = StatsExportDestination.documents,
  }) async {
    final results = <StatsExportFormat, StatsExportResult>{};

    for (final format in StatsExportFormat.values) {
      try {
        results[format] =
            await export(bundle, format, destination: destination);
      } catch (e) {
        debugPrint('Error exporting $format: $e');
      }
    }

    return results;
  }

  Future<Directory> _getDirectory(StatsExportDestination destination) async {
    switch (destination) {
      case StatsExportDestination.documents:
        return await getApplicationDocumentsDirectory();
      case StatsExportDestination.temporary:
        return await getTemporaryDirectory();
      case StatsExportDestination.clipboard:
        throw StateError('Clipboard destination should not reach file export');
    }
  }

  String _getExtension(StatsExportFormat format) {
    return switch (format) {
      StatsExportFormat.json => 'json',
      StatsExportFormat.csv => 'csv',
      StatsExportFormat.pdfLike => 'txt',
    };
  }

  String _generateFilename(StatsExportBundle bundle, String extension) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'eisen_stats_${dateStr}_$timeStr.$extension';
  }
}
