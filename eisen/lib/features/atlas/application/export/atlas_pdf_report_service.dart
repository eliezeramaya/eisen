import 'dart:typed_data';

import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_data.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AtlasPdfReportService {
  const AtlasPdfReportService();

  Future<Uint8List> buildPdf({
    required AtlasPdfData data,
    required AtlasPdfOptions options,
  }) async {
    final format = atlasPdfPageFormat(
      options.paperSize,
      orientation: options.orientation,
    );
    final margin = marginForPaperSize(options.paperSize);
    final marginPt = margin * PdfPageFormat.point;

    final doc = pw.Document(
      title: 'Atlas – Eisen',
      author: 'Eisen',
      creator: 'Eisen App',
    );

    final atlasImage = pw.MemoryImage(data.atlasImageBytes);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(marginPt),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (options.includeTitle) _buildHeader(data, options, margin),
              if (options.includeTitle) pw.SizedBox(height: marginPt * 0.5),
              pw.Expanded(
                child: _buildAtlasImage(atlasImage),
              ),
              if (options.includeLegend) ...[
                pw.SizedBox(height: marginPt * 0.4),
                _buildLegend(),
              ],
              if (options.includeInsights && data.insights.isNotEmpty) ...[
                pw.SizedBox(height: marginPt * 0.4),
                _buildInsights(data.insights),
              ],
              if (options.includeTaskSummary && data.summaryByQuadrant.isNotEmpty) ...[
                pw.SizedBox(height: marginPt * 0.4),
                _buildSummary(data),
              ],
              if (options.includeFooter) ...[
                pw.SizedBox(height: marginPt * 0.4),
                _buildFooter(data, ctx),
              ],
            ],
          );
        },
      ),
    );

    if (options.includeTaskList && data.tasks.isNotEmpty) {
      _addTaskListPages(doc, data, format, marginPt);
    }

    return doc.save();
  }

  pw.Widget _buildHeader(
    AtlasPdfData data,
    AtlasPdfOptions options,
    double margin,
  ) {
    final marginPt = margin * PdfPageFormat.point;
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        vertical: marginPt * 0.3,
        horizontal: marginPt * 0.4,
      ),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Atlas',
                  style: pw.TextStyle(
                    fontSize: _headerFontSize(margin),
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.Text(
                  'Mapa visual de tareas',
                  style: pw.TextStyle(
                    fontSize: _subHeaderFontSize(margin),
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Agrupado por: ${data.groupingLabel}',
                  style: pw.TextStyle(
                    fontSize: _bodyFontSize(margin),
                    color: PdfColors.grey700,
                  ),
                ),
                if (options.includeFilters && data.activeFiltersLabel != null)
                  pw.Text(
                    'Filtros: ${data.activeFiltersLabel}',
                    style: pw.TextStyle(
                      fontSize: _bodyFontSize(margin),
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (options.includeDate)
                pw.Text(
                  _formatDate(data.generatedAt),
                  style: pw.TextStyle(
                    fontSize: _bodyFontSize(margin),
                    color: PdfColors.grey700,
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${data.visibleTaskCount} / ${data.totalTaskCount} tareas',
                style: pw.TextStyle(
                  fontSize: _bodyFontSize(margin),
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAtlasImage(pw.MemoryImage image) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  }

  pw.Widget _buildLegend() {
    const items = [
      (PdfColors.red700, 'Crítico'),
      (PdfColors.green700, 'Crecimiento'),
      (PdfColors.orange700, 'De otros'),
      (PdfColors.grey500, 'Archivar'),
    ];
    return pw.Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final item in items)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  color: item.$1,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                item.$2,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildInsights(List<String> insights) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Insights',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 2),
        for (final insight in insights)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Expanded(
                child: pw.Text(
                  insight,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildSummary(AtlasPdfData data) {
    final entries = data.summaryByQuadrant.entries.where((e) => e.value > 0).toList();

    if (entries.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen por cuadrante',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Wrap(
          spacing: 16,
          runSpacing: 2,
          children: [
            for (final entry in entries)
              pw.Text(
                '${entry.key}: ${entry.value}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(AtlasPdfData data, pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Eisen',
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey400,
          ),
        ),
        pw.Text(
          _formatDateTime(data.generatedAt),
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
        ),
        pw.Text(
          'Página ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
        ),
      ],
    );
  }

  void _addTaskListPages(
    pw.Document doc,
    AtlasPdfData data,
    PdfPageFormat format,
    double marginPt,
  ) {
    const rowsPerPage = 40;
    final tasks = data.tasks;
    final pageCount = (tasks.length / rowsPerPage).ceil();

    for (var pageIdx = 0; pageIdx < pageCount; pageIdx++) {
      final start = pageIdx * rowsPerPage;
      final end = (start + rowsPerPage).clamp(0, tasks.length);
      final pageTasks = tasks.sublist(start, end);

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(marginPt),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'Lista de tareas',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _tableCell('Tarea', bold: true),
                        _tableCell('Cuadrante', bold: true),
                        _tableCell('Categoría', bold: true),
                      ],
                    ),
                    for (final task in pageTasks)
                      pw.TableRow(
                        children: [
                          _tableCell(task.title),
                          _tableCell(_quadrantLabel(task.quadrant)),
                          _tableCell(task.category ?? '—'),
                        ],
                      ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Eisen',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
                    ),
                    pw.Text(
                      'Página ${ctx.pageNumber} / ${ctx.pagesCount}',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
  }

  pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  String _quadrantLabel(dynamic quadrant) {
    final name = quadrant.toString().split('.').last;
    return switch (name) {
      'q1' => 'Crítico',
      'q2' => 'Crecimiento',
      'q3' => 'De otros',
      'q4' => 'Archivar',
      _ => name,
    };
  }

  double _headerFontSize(double margin) {
    if (margin >= 36) return 16;
    if (margin >= 30) return 14;
    return 12;
  }

  double _subHeaderFontSize(double margin) {
    if (margin >= 36) return 10;
    if (margin >= 30) return 9;
    return 8;
  }

  double _bodyFontSize(double margin) {
    if (margin >= 36) return 9;
    if (margin >= 30) return 8;
    return 7.5;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  String _formatDateTime(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final mi = date.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y $h:$mi';
  }
}
