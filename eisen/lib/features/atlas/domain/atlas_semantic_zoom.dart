import 'package:flutter/widgets.dart';

enum AtlasSemanticLevel {
  overview,
  group,
  task,
  detail,
}

extension AtlasSemanticLevelX on AtlasSemanticLevel {
  int? get maxLayoutDepth => switch (this) {
        AtlasSemanticLevel.overview => 0,
        AtlasSemanticLevel.group => 1,
        AtlasSemanticLevel.task => null,
        AtlasSemanticLevel.detail => null,
      };

  bool get showRichTaskContent =>
      this == AtlasSemanticLevel.task || this == AtlasSemanticLevel.detail;
}

class AtlasZoomState {
  const AtlasZoomState({
    required this.scale,
    required this.offset,
    required this.semanticLevel,
    this.focusedGroupId,
  });

  factory AtlasZoomState.initial() {
    return const AtlasZoomState(
      scale: 1,
      offset: Offset.zero,
      semanticLevel: AtlasSemanticLevel.overview,
    );
  }

  final double scale;
  final Offset offset;
  final AtlasSemanticLevel semanticLevel;
  final String? focusedGroupId;

  AtlasZoomState copyWith({
    double? scale,
    Offset? offset,
    AtlasSemanticLevel? semanticLevel,
    String? focusedGroupId,
    bool clearFocusedGroup = false,
  }) {
    return AtlasZoomState(
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      semanticLevel: semanticLevel ?? this.semanticLevel,
      focusedGroupId:
          clearFocusedGroup ? null : (focusedGroupId ?? this.focusedGroupId),
    );
  }

  static AtlasSemanticLevel levelForScale(double scale) {
    if (scale < 1.18) return AtlasSemanticLevel.overview;
    if (scale < 1.9) return AtlasSemanticLevel.group;
    if (scale < 2.8) return AtlasSemanticLevel.task;
    return AtlasSemanticLevel.detail;
  }
}
