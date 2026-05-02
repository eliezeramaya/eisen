import 'package:eisen/features/atlas/domain/atlas_grouping.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:flutter/widgets.dart';

class SavedAtlasFilters {
  const SavedAtlasFilters({
    this.categoryIds = const <String>[],
    this.kinds = const <EntryKind>[],
    this.horizons = const <TimeHorizon>[],
    this.energies = const <EnergyLevel>[],
    this.confidences = const <ConfidenceLevel>[],
  });

  factory SavedAtlasFilters.fromJson(Map<String, Object?> json) {
    return SavedAtlasFilters(
      categoryIds: _stringList(json['categoryIds']),
      kinds: _enumList(json['kinds'], EntryKind.values),
      horizons: _enumList(json['horizons'], TimeHorizon.values),
      energies: _enumList(json['energies'], EnergyLevel.values),
      confidences: _enumList(json['confidences'], ConfidenceLevel.values),
    );
  }

  final List<String> categoryIds;
  final List<EntryKind> kinds;
  final List<TimeHorizon> horizons;
  final List<EnergyLevel> energies;
  final List<ConfidenceLevel> confidences;

  Map<String, Object?> toJson() {
    return {
      'categoryIds': categoryIds,
      'kinds': kinds.map((item) => item.name).toList(growable: false),
      'horizons': horizons.map((item) => item.name).toList(growable: false),
      'energies': energies.map((item) => item.name).toList(growable: false),
      'confidences':
          confidences.map((item) => item.name).toList(growable: false),
    };
  }
}

class SavedAtlasView {
  const SavedAtlasView({
    required this.id,
    required this.name,
    required this.grouping,
    required this.filters,
    required this.showArchived,
    required this.semanticLevel,
    required this.zoomScale,
    required this.zoomOffset,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAtlasView.fromJson(Map<String, Object?> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    return SavedAtlasView(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Vista',
      grouping: atlasGroupingFromName(json['grouping'] as String?),
      filters: SavedAtlasFilters.fromJson(
        (json['filters'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
      showArchived: (json['showArchived'] as bool?) ?? false,
      semanticLevel: _semanticLevelFromName(json['semanticLevel'] as String?),
      zoomScale: ((json['zoomScale'] as num?) ?? 1).toDouble(),
      zoomOffset: Offset(
        ((json['zoomOffsetDx'] as num?) ?? 0).toDouble(),
        ((json['zoomOffsetDy'] as num?) ?? 0).toDouble(),
      ),
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          updatedAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String name;
  final AtlasGrouping grouping;
  final SavedAtlasFilters filters;
  final bool showArchived;
  final AtlasSemanticLevel semanticLevel;
  final double zoomScale;
  final Offset zoomOffset;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedAtlasView copyWith({
    String? name,
    AtlasGrouping? grouping,
    SavedAtlasFilters? filters,
    bool? showArchived,
    AtlasSemanticLevel? semanticLevel,
    double? zoomScale,
    Offset? zoomOffset,
    DateTime? updatedAt,
  }) {
    return SavedAtlasView(
      id: id,
      name: name ?? this.name,
      grouping: grouping ?? this.grouping,
      filters: filters ?? this.filters,
      showArchived: showArchived ?? this.showArchived,
      semanticLevel: semanticLevel ?? this.semanticLevel,
      zoomScale: zoomScale ?? this.zoomScale,
      zoomOffset: zoomOffset ?? this.zoomOffset,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'grouping': grouping.name,
      'filters': filters.toJson(),
      'showArchived': showArchived,
      'semanticLevel': semanticLevel.name,
      'zoomScale': zoomScale,
      'zoomOffsetDx': zoomOffset.dx,
      'zoomOffsetDy': zoomOffset.dy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

List<String> _stringList(Object? raw) {
  return (raw as List?)?.whereType<String>().toList(growable: false) ??
      const <String>[];
}

List<T> _enumList<T extends Enum>(Object? raw, List<T> values) {
  final names = _stringList(raw).toSet();
  return [
    for (final value in values)
      if (names.contains(value.name)) value,
  ];
}

AtlasSemanticLevel _semanticLevelFromName(String? name) {
  for (final level in AtlasSemanticLevel.values) {
    if (level.name == name) return level;
  }
  return AtlasSemanticLevel.overview;
}
