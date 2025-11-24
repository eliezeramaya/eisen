import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/insights_ml/domain/productivity_scores.dart';

/// Placeholder for a future backend ML API.
///
/// This class is intentionally minimal: it documents the contract that a
/// remote service (e.g. XGBoost/LightGBM hosted backend) should expose to
/// replace the on-device heuristics without changing UI or controllers.
class BackendMLApi {
  Future<TaskCompletionPrediction> fetchTaskPrediction(Task task) async =>
      throw UnimplementedError(
          'Pending backend ML integration: replace heuristic with remote model');
}
