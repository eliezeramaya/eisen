import 'package:eisen/features/eisen_matrix/domain/entities.dart';

enum QuadrantLabelStyle {
  classic,
  professional,
  action,
}

class QuadrantLabelData {
  const QuadrantLabelData({
    required this.title,
    required this.subtitle,
    required this.shortLabel,
  });

  final String title;
  final String subtitle;
  final String shortLabel;
}

QuadrantLabelData getQuadrantLabel(
  Quadrant quadrant,
  QuadrantLabelStyle style,
) {
  return switch (style) {
    QuadrantLabelStyle.classic => switch (quadrant) {
        Quadrant.q1 => const QuadrantLabelData(
            title: 'Q1',
            subtitle: 'Urgente e importante',
            shortLabel: 'Q1',
          ),
        Quadrant.q2 => const QuadrantLabelData(
            title: 'Q2',
            subtitle: 'Importante, no urgente',
            shortLabel: 'Q2',
          ),
        Quadrant.q3 => const QuadrantLabelData(
            title: 'Q3',
            subtitle: 'Urgente, no importante',
            shortLabel: 'Q3',
          ),
        Quadrant.q4 => const QuadrantLabelData(
            title: 'Q4',
            subtitle: 'No urgente, no importante',
            shortLabel: 'Q4',
          ),
      },
    QuadrantLabelStyle.professional => switch (quadrant) {
        Quadrant.q1 => const QuadrantLabelData(
            title: 'Crítico',
            subtitle: 'Requiere atención inmediata',
            shortLabel: 'Crítico',
          ),
        Quadrant.q2 => const QuadrantLabelData(
            title: 'Crecimiento',
            subtitle: 'Aporta valor a largo plazo',
            shortLabel: 'Crecimiento',
          ),
        Quadrant.q3 => const QuadrantLabelData(
            title: 'De otros',
            subtitle: 'Urgente, pero no importante',
            shortLabel: 'De otros',
          ),
        Quadrant.q4 => const QuadrantLabelData(
            title: 'Archivar',
            subtitle: 'Guardar para consulta futura',
            shortLabel: 'Archivar',
          ),
      },
    QuadrantLabelStyle.action => switch (quadrant) {
        Quadrant.q1 => const QuadrantLabelData(
            title: 'Haz ahora',
            subtitle: 'Resuélvelo cuanto antes',
            shortLabel: 'Ahora',
          ),
        Quadrant.q2 => const QuadrantLabelData(
            title: 'Planifica',
            subtitle: 'Agenda tiempo para avanzar',
            shortLabel: 'Planifica',
          ),
        Quadrant.q3 => const QuadrantLabelData(
            title: 'Delega',
            subtitle: 'Reduce o delega estas demandas externas',
            shortLabel: 'Delega',
          ),
        Quadrant.q4 => const QuadrantLabelData(
            title: 'Archivar',
            subtitle: 'Guardar para consulta futura',
            shortLabel: 'Archivar',
          ),
      },
  };
}

QuadrantLabelStyle quadrantLabelStyleFromName(String? name) {
  for (final style in QuadrantLabelStyle.values) {
    if (style.name == name) return style;
  }
  return QuadrantLabelStyle.professional;
}
