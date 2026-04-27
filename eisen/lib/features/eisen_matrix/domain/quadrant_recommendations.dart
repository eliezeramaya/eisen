import 'package:eisen/features/eisen_matrix/domain/entities.dart';

class QuadrantActionData {
  const QuadrantActionData({
    required this.recommendation,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
  });

  final String recommendation;
  final String primaryActionLabel;
  final String secondaryActionLabel;
}

String getQuadrantRecommendation(Quadrant quadrant) {
  return getQuadrantActionData(quadrant).recommendation;
}

QuadrantActionData getQuadrantActionData(Quadrant quadrant) {
  return switch (quadrant) {
    Quadrant.q1 => const QuadrantActionData(
        recommendation: 'Enfócate en esto primero',
        primaryActionLabel: 'Iniciar foco',
        secondaryActionLabel: 'Dividir tarea',
      ),
    Quadrant.q2 => const QuadrantActionData(
        recommendation: 'Agenda tiempo para avanzar',
        primaryActionLabel: 'Agendar',
        secondaryActionLabel: 'Convertir en hábito',
      ),
    Quadrant.q3 => const QuadrantActionData(
        recommendation: '¿Puedes delegarlo o limitarlo?',
        primaryActionLabel: 'Delegar',
        secondaryActionLabel: 'Limitar',
      ),
    Quadrant.q4 => const QuadrantActionData(
        recommendation: 'Guárdalo para consulta futura',
        primaryActionLabel: 'Archivar',
        secondaryActionLabel: 'Revisar después',
      ),
  };
}
