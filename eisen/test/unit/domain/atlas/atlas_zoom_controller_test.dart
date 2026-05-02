import 'package:eisen/features/atlas/application/atlas_zoom_controller.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('levelForScale asigna niveles semánticos por escala', () {
    expect(AtlasZoomState.levelForScale(1), AtlasSemanticLevel.overview);
    expect(AtlasZoomState.levelForScale(1.3), AtlasSemanticLevel.group);
    expect(AtlasZoomState.levelForScale(2.2), AtlasSemanticLevel.task);
    expect(AtlasZoomState.levelForScale(3.1), AtlasSemanticLevel.detail);
  });

  test('AtlasZoomController actualiza escala, offset y nivel', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(atlasZoomProvider.notifier).updateFromTransform(
          scale: 2.1,
          offset: const Offset(12, -8),
        );

    final state = container.read(atlasZoomProvider);
    expect(state.scale, 2.1);
    expect(state.offset, const Offset(12, -8));
    expect(state.semanticLevel, AtlasSemanticLevel.task);
  });

  test('reset vuelve a overview', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(atlasZoomProvider.notifier).zoomIn();
    container.read(atlasZoomProvider.notifier).reset();

    final state = container.read(atlasZoomProvider);
    expect(state.scale, 1);
    expect(state.offset, Offset.zero);
    expect(state.semanticLevel, AtlasSemanticLevel.overview);
  });
}
