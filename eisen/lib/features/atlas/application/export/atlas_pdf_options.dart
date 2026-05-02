import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';

class AtlasPdfOptions {
  const AtlasPdfOptions({
    this.paperSize = AtlasPaperSize.archB,
    this.orientation = AtlasPaperOrientation.landscape,
    this.includeTitle = true,
    this.includeDate = true,
    this.includeLegend = true,
    this.includeInsights = true,
    this.includeFilters = true,
    this.includeTaskSummary = true,
    this.includeTaskList = false,
    this.includeFooter = true,
    this.pixelRatio = 3.0,
  });

  final AtlasPaperSize paperSize;
  final AtlasPaperOrientation orientation;
  final bool includeTitle;
  final bool includeDate;
  final bool includeLegend;
  final bool includeInsights;
  final bool includeFilters;
  final bool includeTaskSummary;
  final bool includeTaskList;
  final bool includeFooter;
  final double pixelRatio;

  AtlasPdfOptions copyWith({
    AtlasPaperSize? paperSize,
    AtlasPaperOrientation? orientation,
    bool? includeTitle,
    bool? includeDate,
    bool? includeLegend,
    bool? includeInsights,
    bool? includeFilters,
    bool? includeTaskSummary,
    bool? includeTaskList,
    bool? includeFooter,
    double? pixelRatio,
  }) {
    return AtlasPdfOptions(
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      includeTitle: includeTitle ?? this.includeTitle,
      includeDate: includeDate ?? this.includeDate,
      includeLegend: includeLegend ?? this.includeLegend,
      includeInsights: includeInsights ?? this.includeInsights,
      includeFilters: includeFilters ?? this.includeFilters,
      includeTaskSummary: includeTaskSummary ?? this.includeTaskSummary,
      includeTaskList: includeTaskList ?? this.includeTaskList,
      includeFooter: includeFooter ?? this.includeFooter,
      pixelRatio: pixelRatio ?? this.pixelRatio,
    );
  }
}
