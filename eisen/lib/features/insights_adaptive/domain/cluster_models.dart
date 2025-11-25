import 'package:flutter/foundation.dart';

enum ProductivityCluster {
  unknown,
  nightSprinter,
  morningStrong,
  starterButNotFinisher,
}

@immutable
class UserProductivityProfile {
  const UserProductivityProfile({
    required this.cluster,
    required this.computedAt,
  });

  final ProductivityCluster cluster;
  final DateTime computedAt;
}
