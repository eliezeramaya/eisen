import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';

abstract class ProductivityClusteringService {
  Future<UserProductivityProfile> computeWeeklyProfile(DateTime now);
}
