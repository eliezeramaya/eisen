import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quadrant labels', () {
    test('professional labels are user-facing and human', () {
      expect(
        getQuadrantLabel(Quadrant.q1, QuadrantLabelStyle.professional).title,
        'Crítico',
      );
      expect(
        getQuadrantLabel(Quadrant.q2, QuadrantLabelStyle.professional).title,
        'Crecimiento',
      );
      expect(
        getQuadrantLabel(Quadrant.q3, QuadrantLabelStyle.professional).title,
        'De otros',
      );
      expect(
        getQuadrantLabel(Quadrant.q4, QuadrantLabelStyle.professional).title,
        'Archivar',
      );
    });

    test('action labels use action-oriented names', () {
      expect(
        getQuadrantLabel(Quadrant.q1, QuadrantLabelStyle.action).title,
        'Haz ahora',
      );
      expect(
        getQuadrantLabel(Quadrant.q2, QuadrantLabelStyle.action).title,
        'Planifica',
      );
      expect(
        getQuadrantLabel(Quadrant.q3, QuadrantLabelStyle.action).title,
        'Delega',
      );
      expect(
        getQuadrantLabel(Quadrant.q4, QuadrantLabelStyle.action).title,
        'Archivar',
      );
    });

    test('Q4 never uses eliminar in professional or action styles', () {
      final professional =
          getQuadrantLabel(Quadrant.q4, QuadrantLabelStyle.professional);
      final action = getQuadrantLabel(Quadrant.q4, QuadrantLabelStyle.action);

      expect(professional.title, 'Archivar');
      expect(action.title, 'Archivar');
      expect(professional.title.toLowerCase(), isNot(contains('eliminar')));
      expect(action.title.toLowerCase(), isNot(contains('eliminar')));
    });
  });
}
