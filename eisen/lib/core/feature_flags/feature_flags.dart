import 'package:eisen/core/config/app_config.dart';

enum FeatureFlag {
  smartClassification,
  classificationLearning,
  quadrantAwareScoring,
  archive,
  cloudSync,
  analytics,
  crashReporting,
  savedViews,
  reviewCenter,
}

class FeatureFlags {
  const FeatureFlags({
    required this.values,
  });

  factory FeatureFlags.defaults(AppConfig config) {
    return FeatureFlags(
      values: <FeatureFlag, bool>{
        FeatureFlag.smartClassification: true,
        FeatureFlag.classificationLearning: config.enableClassificationLearning,
        FeatureFlag.quadrantAwareScoring: true,
        FeatureFlag.archive: config.enableArchive,
        FeatureFlag.cloudSync: config.isCloudSyncEnabled,
        FeatureFlag.analytics: config.isAnalyticsConfigured,
        FeatureFlag.crashReporting: config.isCrashReportingConfigured,
        FeatureFlag.savedViews: true,
        FeatureFlag.reviewCenter: true,
      },
    );
  }

  final Map<FeatureFlag, bool> values;

  bool isEnabled(FeatureFlag flag) => values[flag] ?? false;

  FeatureFlags copyWithOverride(FeatureFlag flag, bool? enabled) {
    final next = Map<FeatureFlag, bool>.of(values);
    if (enabled != null) {
      next[flag] = enabled;
    }
    return FeatureFlags(values: next);
  }
}

extension FeatureFlagKey on FeatureFlag {
  String get storageName => name;
}
