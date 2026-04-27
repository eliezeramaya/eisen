import 'package:eisen/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default config is dev and local-first', () {
    final config = AppConfig.fromEnvironment();

    expect(config.environment, AppEnvironment.dev);
    expect(config.isDev, isTrue);
    expect(config.isProd, isFalse);
    expect(config.enableCloudSync, isFalse);
    expect(config.isCloudSyncEnabled, isFalse);
  });

  test('analytics and crash reporting are disabled without keys', () {
    final config = AppConfig.fromEnvironment();

    expect(config.isAnalyticsConfigured, isFalse);
    expect(config.isCrashReportingConfigured, isFalse);
  });
}
