import 'package:eisen/core/config/app_config.dart';

class AnalyticsEvents {
  const AnalyticsEvents._();

  static const taskCreated = 'task_created';
  static const taskArchived = 'task_archived';
  static const taskCompleted = 'task_completed';
  static const classificationPreviewed = 'classification_previewed';
  static const classificationCorrected = 'classification_corrected';
  static const filterApplied = 'filter_applied';
  static const quadrantChanged = 'quadrant_changed';
  static const ruleSuggestionCreated = 'rule_suggestion_created';
  static const settingsChanged = 'settings_changed';
}

class AnalyticsProperties {
  const AnalyticsProperties._();

  static Map<String, Object?> common({
    required AppConfig config,
    String? source,
    String? quadrant,
    String? category,
    String? confidence,
    bool? hasAutoTags,
    String appVersion = 'unknown',
  }) {
    return <String, Object?>{
      'app_version': appVersion,
      'environment': config.environment.name,
      if (source != null) 'source': source,
      if (quadrant != null) 'quadrant': quadrant,
      if (category != null) 'category': category,
      if (confidence != null) 'confidence': confidence,
      if (hasAutoTags != null) 'has_auto_tags': hasAutoTags,
    };
  }
}
