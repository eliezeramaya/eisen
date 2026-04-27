enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.sentryDsn,
    required this.analyticsKey,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enableCloudSync,
    required this.enableClassificationLearning,
    required this.enableArchive,
    required this.enableDebugLogs,
    required this.localSchemaVersion,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      environment: AppEnvironment.parse(
        const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev'),
      ),
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
      analyticsKey: const String.fromEnvironment('ANALYTICS_KEY'),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      enableAnalytics: const bool.fromEnvironment('ENABLE_ANALYTICS'),
      enableCrashReporting:
          const bool.fromEnvironment('ENABLE_CRASH_REPORTING'),
      enableCloudSync: const bool.fromEnvironment('ENABLE_CLOUD_SYNC'),
      enableClassificationLearning: const bool.fromEnvironment(
        'ENABLE_CLASSIFICATION_LEARNING',
        defaultValue: true,
      ),
      enableArchive: const bool.fromEnvironment(
        'ENABLE_ARCHIVE',
        defaultValue: true,
      ),
      enableDebugLogs: const bool.fromEnvironment(
        'ENABLE_DEBUG_LOGS',
        defaultValue: true,
      ),
      localSchemaVersion: const int.fromEnvironment(
        'LOCAL_SCHEMA_VERSION',
        defaultValue: 1,
      ),
    );
  }

  static final AppConfig current = AppConfig.fromEnvironment();

  final AppEnvironment environment;
  final String sentryDsn;
  final String analyticsKey;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableCloudSync;
  final bool enableClassificationLearning;
  final bool enableArchive;
  final bool enableDebugLogs;
  final int localSchemaVersion;

  bool get isProd => environment == AppEnvironment.prod;
  bool get isDev => environment == AppEnvironment.dev;
  bool get isCloudSyncEnabled =>
      enableCloudSync &&
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;

  bool get isCrashReportingConfigured =>
      enableCrashReporting && sentryDsn.trim().isNotEmpty;

  bool get isAnalyticsConfigured =>
      enableAnalytics && analyticsKey.trim().isNotEmpty;
}
