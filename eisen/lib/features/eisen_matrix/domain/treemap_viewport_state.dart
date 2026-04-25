import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/foundation.dart';

enum TreemapZoomLevel {
  global,
  category,
  subcategory,
  group,
  task,
}

enum TreemapGrouping {
  category,
  kind,
  horizon,
  energy,
  client,
  project,
  tag,
  confidence,
  context,
}

enum TreemapVisualDensity {
  comfy,
  balanced,
  compact,
  advanced,
}

enum TreemapQuickFilter {
  today,
  week,
  highPriority,
  lowConfidence,
  lowEnergy,
}

@immutable
class TreemapViewportState {
  const TreemapViewportState({
    this.zoomLevel = TreemapZoomLevel.global,
    this.selectedQuadrant,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.selectedGroupId,
    this.selectedTaskId,
    this.selectedNodeId,
    this.grouping = TreemapGrouping.category,
    this.density = TreemapVisualDensity.balanced,
    this.breadcrumbPath = const <String>['Todo'],
    this.quickFilter,
    this.activeSearchQuery,
    this.updatedAt,
  });

  final TreemapZoomLevel zoomLevel;
  final Quadrant? selectedQuadrant;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final String? selectedGroupId;
  final String? selectedTaskId;
  final String? selectedNodeId;
  final TreemapGrouping grouping;
  final TreemapVisualDensity density;
  final List<String> breadcrumbPath;
  final TreemapQuickFilter? quickFilter;
  final String? activeSearchQuery;
  final DateTime? updatedAt;

  bool get isGlobal => zoomLevel == TreemapZoomLevel.global;
  bool get isSemanticDetail => zoomLevel != TreemapZoomLevel.global;
  List<String> get activeFilters =>
      quickFilter == null ? const <String>[] : <String>[quickFilter!.name];

  TreemapViewportState copyWith({
    TreemapZoomLevel? zoomLevel,
    Object? selectedQuadrant = _sentinel,
    Object? selectedCategoryId = _sentinel,
    Object? selectedSubcategoryId = _sentinel,
    Object? selectedGroupId = _sentinel,
    Object? selectedTaskId = _sentinel,
    Object? selectedNodeId = _sentinel,
    TreemapGrouping? grouping,
    TreemapVisualDensity? density,
    List<String>? breadcrumbPath,
    Object? quickFilter = _sentinel,
    Object? activeSearchQuery = _sentinel,
    DateTime? updatedAt,
  }) {
    return TreemapViewportState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      selectedQuadrant: identical(selectedQuadrant, _sentinel)
          ? this.selectedQuadrant
          : selectedQuadrant as Quadrant?,
      selectedCategoryId: identical(selectedCategoryId, _sentinel)
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      selectedSubcategoryId: identical(selectedSubcategoryId, _sentinel)
          ? this.selectedSubcategoryId
          : selectedSubcategoryId as String?,
      selectedGroupId: identical(selectedGroupId, _sentinel)
          ? this.selectedGroupId
          : selectedGroupId as String?,
      selectedTaskId: identical(selectedTaskId, _sentinel)
          ? this.selectedTaskId
          : selectedTaskId as String?,
      selectedNodeId: identical(selectedNodeId, _sentinel)
          ? this.selectedNodeId
          : selectedNodeId as String?,
      grouping: grouping ?? this.grouping,
      density: density ?? this.density,
      breadcrumbPath: breadcrumbPath ?? this.breadcrumbPath,
      quickFilter: identical(quickFilter, _sentinel)
          ? this.quickFilter
          : quickFilter as TreemapQuickFilter?,
      activeSearchQuery: identical(activeSearchQuery, _sentinel)
          ? this.activeSearchQuery
          : activeSearchQuery as String?,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TreemapViewportState.fromJson(Map<String, Object?> json) {
    return TreemapViewportState(
      zoomLevel: _zoomLevelFromName(json['zoomLevel'] as String?),
      selectedQuadrant: _quadrantFromJson(json['selectedQuadrant']),
      selectedCategoryId: json['selectedCategoryId'] as String?,
      selectedSubcategoryId: json['selectedSubcategoryId'] as String?,
      selectedGroupId: json['selectedGroupId'] as String?,
      selectedTaskId: json['selectedTaskId'] as String?,
      selectedNodeId: json['selectedNodeId'] as String?,
      grouping: _groupingFromName(json['grouping'] as String?),
      density: _densityFromName(json['density'] as String?),
      breadcrumbPath:
          (json['breadcrumbPath'] as List?)?.cast<String>() ?? const ['Todo'],
      quickFilter: _quickFilterFromName(json['quickFilter'] as String?),
      activeSearchQuery: json['activeSearchQuery'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'zoomLevel': zoomLevel.name,
        'selectedQuadrant': selectedQuadrant?.name,
        'selectedCategoryId': selectedCategoryId,
        'selectedSubcategoryId': selectedSubcategoryId,
        'selectedGroupId': selectedGroupId,
        'selectedTaskId': selectedTaskId,
        'selectedNodeId': selectedNodeId,
        'grouping': grouping.name,
        'density': density.name,
        'breadcrumbPath': breadcrumbPath,
        'quickFilter': quickFilter?.name,
        'activeSearchQuery': activeSearchQuery,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static const Object _sentinel = Object();
}

TreemapZoomLevel _zoomLevelFromName(String? name) {
  for (final value in TreemapZoomLevel.values) {
    if (value.name == name) return value;
  }
  return TreemapZoomLevel.global;
}

TreemapGrouping _groupingFromName(String? name) {
  for (final value in TreemapGrouping.values) {
    if (value.name == name) return value;
  }
  return TreemapGrouping.category;
}

TreemapVisualDensity _densityFromName(String? name) {
  for (final value in TreemapVisualDensity.values) {
    if (value.name == name) return value;
  }
  return TreemapVisualDensity.balanced;
}

TreemapQuickFilter? _quickFilterFromName(String? name) {
  for (final value in TreemapQuickFilter.values) {
    if (value.name == name) return value;
  }
  return null;
}

Quadrant? _quadrantFromJson(Object? raw) {
  final name = raw as String?;
  if (name == null) return null;
  for (final value in Quadrant.values) {
    if (value.name == name) return value;
  }
  return null;
}
