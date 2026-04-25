import 'package:eisen/features/eisen_matrix/domain/treemap_viewport_state.dart';
import 'package:flutter/foundation.dart';

@immutable
class TreemapViewPreferences {
  const TreemapViewPreferences({
    this.colorByCategory = true,
    this.showConfidenceIndicators = true,
    this.showAutoTags = true,
    this.defaultGrouping = TreemapGrouping.category,
    this.defaultZoomLevel = TreemapZoomLevel.global,
    this.visualDensity = TreemapVisualDensity.balanced,
    this.showBreadcrumbs = true,
    this.enableSemanticZoom = true,
    this.enablePinchZoom = true,
    this.enableDoubleTapZoom = true,
    this.showMinimap = false,
    this.showTaskCountInGroups = true,
    this.showEstimatedMinutes = true,
    this.updatedAt,
  });

  final bool colorByCategory;
  final bool showConfidenceIndicators;
  final bool showAutoTags;
  final TreemapGrouping defaultGrouping;
  final TreemapZoomLevel defaultZoomLevel;
  final TreemapVisualDensity visualDensity;
  final bool showBreadcrumbs;
  final bool enableSemanticZoom;
  final bool enablePinchZoom;
  final bool enableDoubleTapZoom;
  final bool showMinimap;
  final bool showTaskCountInGroups;
  final bool showEstimatedMinutes;
  final DateTime? updatedAt;

  TreemapViewPreferences copyWith({
    bool? colorByCategory,
    bool? showConfidenceIndicators,
    bool? showAutoTags,
    TreemapGrouping? defaultGrouping,
    TreemapZoomLevel? defaultZoomLevel,
    TreemapVisualDensity? visualDensity,
    bool? showBreadcrumbs,
    bool? enableSemanticZoom,
    bool? enablePinchZoom,
    bool? enableDoubleTapZoom,
    bool? showMinimap,
    bool? showTaskCountInGroups,
    bool? showEstimatedMinutes,
    DateTime? updatedAt,
  }) {
    return TreemapViewPreferences(
      colorByCategory: colorByCategory ?? this.colorByCategory,
      showConfidenceIndicators:
          showConfidenceIndicators ?? this.showConfidenceIndicators,
      showAutoTags: showAutoTags ?? this.showAutoTags,
      defaultGrouping: defaultGrouping ?? this.defaultGrouping,
      defaultZoomLevel: defaultZoomLevel ?? this.defaultZoomLevel,
      visualDensity: visualDensity ?? this.visualDensity,
      showBreadcrumbs: showBreadcrumbs ?? this.showBreadcrumbs,
      enableSemanticZoom: enableSemanticZoom ?? this.enableSemanticZoom,
      enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
      enableDoubleTapZoom: enableDoubleTapZoom ?? this.enableDoubleTapZoom,
      showMinimap: showMinimap ?? this.showMinimap,
      showTaskCountInGroups:
          showTaskCountInGroups ?? this.showTaskCountInGroups,
      showEstimatedMinutes: showEstimatedMinutes ?? this.showEstimatedMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TreemapViewPreferences.fromJson(Map<String, Object?> json) {
    return TreemapViewPreferences(
      colorByCategory: json['colorByCategory'] as bool? ?? true,
      showConfidenceIndicators:
          json['showConfidenceIndicators'] as bool? ?? true,
      showAutoTags: json['showAutoTags'] as bool? ?? true,
      defaultGrouping: _groupingFromName(
        json['defaultGrouping'] as String?,
      ),
      defaultZoomLevel: _zoomLevelFromName(
        json['defaultZoomLevel'] as String?,
      ),
      visualDensity: _densityFromName(
        json['visualDensity'] as String?,
      ),
      showBreadcrumbs: json['showBreadcrumbs'] as bool? ?? true,
      enableSemanticZoom: json['enableSemanticZoom'] as bool? ?? true,
      enablePinchZoom: json['enablePinchZoom'] as bool? ?? true,
      enableDoubleTapZoom: json['enableDoubleTapZoom'] as bool? ?? true,
      showMinimap: json['showMinimap'] as bool? ?? false,
      showTaskCountInGroups: json['showTaskCountInGroups'] as bool? ?? true,
      showEstimatedMinutes: json['showEstimatedMinutes'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
        'colorByCategory': colorByCategory,
        'showConfidenceIndicators': showConfidenceIndicators,
        'showAutoTags': showAutoTags,
        'defaultGrouping': defaultGrouping.name,
        'defaultZoomLevel': defaultZoomLevel.name,
        'visualDensity': visualDensity.name,
        'showBreadcrumbs': showBreadcrumbs,
        'enableSemanticZoom': enableSemanticZoom,
        'enablePinchZoom': enablePinchZoom,
        'enableDoubleTapZoom': enableDoubleTapZoom,
        'showMinimap': showMinimap,
        'showTaskCountInGroups': showTaskCountInGroups,
        'showEstimatedMinutes': showEstimatedMinutes,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class TreemapViewPreferencesDefaults {
  const TreemapViewPreferencesDefaults._();

  static const value = TreemapViewPreferences();
}

TreemapGrouping _groupingFromName(String? name) {
  for (final value in TreemapGrouping.values) {
    if (value.name == name) return value;
  }
  return TreemapGrouping.category;
}

TreemapZoomLevel _zoomLevelFromName(String? name) {
  for (final value in TreemapZoomLevel.values) {
    if (value.name == name) return value;
  }
  return TreemapZoomLevel.global;
}

TreemapVisualDensity _densityFromName(String? name) {
  for (final value in TreemapVisualDensity.values) {
    if (value.name == name) return value;
  }
  return TreemapVisualDensity.balanced;
}
