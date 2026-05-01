import 'package:eisen/features/atlas/domain/atlas_color_resolver.dart';
import 'package:eisen/features/atlas/domain/atlas_visual_encoding.dart';
import 'package:eisen/features/classification/domain/enums/confidence_level.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada cuadrante tiene color distinto', () {
    final colors = Quadrant.values
        .map((q) => atlasColorForQuadrant(q, Brightness.light))
        .toSet();

    expect(colors, hasLength(4));
  });

  test('Q4 es más muted', () {
    final q1 = HSLColor.fromColor(
      atlasMutedColorForQuadrant(Quadrant.q1, Brightness.light),
    );
    final q4 = HSLColor.fromColor(
      atlasMutedColorForQuadrant(Quadrant.q4, Brightness.light),
    );

    expect(q4.saturation, lessThan(q1.saturation));
  });

  test('baja confianza activa borde', () {
    final encoding = resolveAtlasVisualEncoding(
      task: _task(confidence: ConfidenceLevel.low),
      theme: ThemeData.light(),
      isFocused: false,
    );

    expect(encoding.showConfidenceBorder, isTrue);
  });
}

Task _task({ConfidenceLevel? confidence}) {
  return Task(
    id: '1',
    title: 'Task',
    quadrant: Quadrant.q2,
    priority: 5,
    minutes: 30,
    classificationConfidence: confidence,
  );
}
