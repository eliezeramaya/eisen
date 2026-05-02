import 'dart:math' as math;

import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final atlasZoomProvider = NotifierProvider<AtlasZoomController, AtlasZoomState>(
  AtlasZoomController.new,
);

class AtlasZoomController extends Notifier<AtlasZoomState> {
  static const double minScale = 1;
  static const double maxScale = 4;

  @override
  AtlasZoomState build() => AtlasZoomState.initial();

  void updateFromTransform({
    required double scale,
    required Offset offset,
  }) {
    final clampedScale = scale.clamp(minScale, maxScale).toDouble();
    state = state.copyWith(
      scale: clampedScale,
      offset: offset,
      semanticLevel: AtlasZoomState.levelForScale(clampedScale),
    );
  }

  void zoomIn() {
    _setScale(state.scale * 1.35);
  }

  void zoomOut() {
    _setScale(state.scale / 1.35);
  }

  void reset() {
    state = AtlasZoomState.initial();
  }

  void applySavedZoom({
    required double scale,
    required Offset offset,
    required AtlasSemanticLevel semanticLevel,
  }) {
    final clampedScale = scale.clamp(minScale, maxScale).toDouble();
    state = state.copyWith(
      scale: clampedScale,
      offset: offset,
      semanticLevel: semanticLevel,
      clearFocusedGroup: true,
    );
  }

  void focusGroup(String? groupId) {
    state = state.copyWith(
      focusedGroupId: groupId,
      clearFocusedGroup: groupId == null,
    );
  }

  void _setScale(double nextScale) {
    final clamped = math.max(minScale, math.min(maxScale, nextScale));
    state = state.copyWith(
      scale: clamped,
      semanticLevel: AtlasZoomState.levelForScale(clamped),
    );
  }
}
