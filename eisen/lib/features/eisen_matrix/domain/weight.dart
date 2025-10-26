import 'package:eisen/features/eisen_matrix/domain/entities.dart';

export 'entities.dart' show Quadrant, Task;

double taskWeight(Task t) => weight(t);

/// Centralized importance weight. Currently delegates to [weight] from
/// entities.dart but allows future evolution without touching call sites.
double importanceWeight(Task t, {DateTime? now}) => weight(t);
