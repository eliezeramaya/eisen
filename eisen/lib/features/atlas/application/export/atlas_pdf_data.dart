import 'dart:typed_data';

import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class AtlasPdfData {
  const AtlasPdfData({
    required this.generatedAt,
    required this.groupingLabel,
    required this.visibleTaskCount,
    required this.totalTaskCount,
    required this.tasks,
    required this.atlasImageBytes,
    this.activeFiltersLabel,
    this.insights = const [],
    this.summaryByQuadrant = const {},
    this.summaryByCategory = const {},
  });

  final DateTime generatedAt;
  final String groupingLabel;
  final int visibleTaskCount;
  final int totalTaskCount;
  final List<Task> tasks;
  final Uint8List atlasImageBytes;
  final String? activeFiltersLabel;
  final List<String> insights;
  final Map<String, int> summaryByQuadrant;
  final Map<String, int> summaryByCategory;
}
