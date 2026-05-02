import 'package:eisen/features/atlas/application/export/atlas_pdf_data.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_report_service.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_export_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class AtlasPrintPreviewScreen extends StatefulWidget {
  const AtlasPrintPreviewScreen({
    super.key,
    required this.data,
    this.initialOptions = const AtlasPdfOptions(),
  });

  final AtlasPdfData data;
  final AtlasPdfOptions initialOptions;

  @override
  State<AtlasPrintPreviewScreen> createState() =>
      _AtlasPrintPreviewScreenState();
}

class _AtlasPrintPreviewScreenState extends State<AtlasPrintPreviewScreen> {
  late AtlasPdfOptions _options;
  static const _reportService = AtlasPdfReportService();

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
  }

  void _showOptions() {
    showModalBottomSheet<AtlasPdfOptions>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => AtlasExportOptionsSheet(
        options: _options,
        onChanged: (updated) {
          setState(() {
            _options = updated;
          });
          Navigator.of(context).pop(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Atlas'),
        actions: [
          IconButton(
            tooltip: 'Opciones de exportación',
            icon: const Icon(Icons.tune_outlined),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: PdfPreview(
        // Always use our configured options, ignoring PdfPreview's injected format.
        build: (format) async {
          return _reportService.buildPdf(
            data: widget.data,
            options: _options,
          );
        },
        // Re-build when options change via key.
        key: ValueKey(_options.hashCode),
        useActions: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: _buildFilename(),
        loadingWidget: const Center(
          child: CircularProgressIndicator(),
        ),
        onError: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo generar el PDF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Intenta de nuevo cuando el mapa termine de cargar.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildFilename() {
    final d = widget.data.generatedAt;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'eisen-atlas-$y-$m-$day.pdf';
  }
}
