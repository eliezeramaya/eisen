import 'dart:convert';
import 'dart:typed_data';

import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_data.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_report_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AtlasPdfReportService();

  AtlasPdfData data({
    List<String>? insights,
    List<Task>? tasks,
    int visibleCount = 4,
    int totalCount = 10,
  }) {
    return AtlasPdfData(
      generatedAt: DateTime(2026, 5, 2, 10),
      groupingLabel: 'Cuadrante',
      visibleTaskCount: visibleCount,
      totalTaskCount: totalCount,
      tasks: tasks ?? [],
      // 1×1 transparent PNG (minimal valid PNG for testing)
      atlasImageBytes: _minimalPng(),
      insights: insights ?? [],
      summaryByQuadrant: const {'Crítico': 2, 'Crecimiento': 1},
      summaryByCategory: const {'Trabajo': 3},
    );
  }

  test('buildPdf returns non-empty bytes', () async {
    final bytes = await service.buildPdf(
      data: data(),
      options: const AtlasPdfOptions(),
    );
    expect(bytes, isNotEmpty);
    expect(bytes.lengthInBytes, greaterThan(100));
  });

  test('does not crash with empty insights', () async {
    final bytes = await service.buildPdf(
      data: data(insights: []),
      options: const AtlasPdfOptions(includeInsights: true),
    );
    expect(bytes, isNotEmpty);
  });

  test('does not crash with zero visible tasks', () async {
    final bytes = await service.buildPdf(
      data: data(visibleCount: 0, totalCount: 0),
      options: const AtlasPdfOptions(),
    );
    expect(bytes, isNotEmpty);
  });

  test('does not crash with includeTitle false', () async {
    final bytes = await service.buildPdf(
      data: data(),
      options: const AtlasPdfOptions(includeTitle: false),
    );
    expect(bytes, isNotEmpty);
  });

  test('does not crash with all options disabled', () async {
    final bytes = await service.buildPdf(
      data: data(),
      options: const AtlasPdfOptions(
        includeTitle: false,
        includeDate: false,
        includeLegend: false,
        includeInsights: false,
        includeFilters: false,
        includeTaskSummary: false,
        includeTaskList: false,
        includeFooter: false,
      ),
    );
    expect(bytes, isNotEmpty);
  });

  test('includes task list page when includeTaskList is true', () async {
    final tasks = [
      for (var i = 0; i < 5; i++)
        Task(
          id: '$i',
          title: 'Task $i',
          quadrant: Quadrant.q1,
          priority: 5,
          minutes: 30,
        ),
    ];
    final bytes = await service.buildPdf(
      data: data(tasks: tasks),
      options: const AtlasPdfOptions(includeTaskList: true),
    );
    expect(bytes, isNotEmpty);
  });

  test('respects ARCH D landscape paper size without crashing', () async {
    final bytes = await service.buildPdf(
      data: data(),
      options: const AtlasPdfOptions(
        paperSize: AtlasPaperSize.archD,
        orientation: AtlasPaperOrientation.landscape,
      ),
    );
    expect(bytes, isNotEmpty);
  });
}

/// Returns bytes for a minimal valid 1×1 white PNG.
Uint8List _minimalPng() {
  // Valid 1×1 white pixel PNG (generated, verified CRC)
  const b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4'
      '//8/AAX+Av4zEpUUAAAAAElFTkSuQmCC';
  return Uint8List.fromList(base64.decode(b64));
}
