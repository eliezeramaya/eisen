class LocalStorageKeys {
  const LocalStorageKeys._();

  static const tasksPayload = 'eisen.tasks.v1';
  static const telemetryConsent = 'eisen.telemetry.consent.v1';
  static const telemetrySalt = 'eisen.telemetry.salt.v1';

  static const uiPrefs = 'ui.prefs';
  static const settingsPrefix = 'settings.';
  static const filtersPrefix = 'filters.';
  static const featureFlagsPrefix = 'feature_flags.';
  static const onboardingPrefix = 'onboarding.';
  static const localSchemaPrefix = 'local_schema.';

  static const filtersCategories = '${filtersPrefix}categories';
  static const filtersKinds = '${filtersPrefix}kinds';
  static const filtersHorizons = '${filtersPrefix}horizons';
  static const filtersEnergies = '${filtersPrefix}energies';
  static const filtersConfidences = '${filtersPrefix}confidences';

  static const taskViewMode = '${settingsPrefix}task_view_mode';

  static const localSchemaVersion = '${localSchemaPrefix}version';
  static const localSchemaLastMigratedAt =
      '${localSchemaPrefix}last_migrated_at';

  static String featureFlagOverride(String flagName) {
    return '$featureFlagsPrefix$flagName';
  }
}
