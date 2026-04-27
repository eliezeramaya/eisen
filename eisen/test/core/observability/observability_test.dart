import 'package:eisen/core/config/app_config.dart';
import 'package:eisen/core/observability/analytics_service.dart';
import 'package:eisen/core/observability/app_logger.dart';
import 'package:eisen/core/observability/error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('noop reporter and analytics do not throw', () async {
    final logger = ConsoleAppLogger(config: AppConfig.fromEnvironment());
    final reporter = NoopErrorReporter(logger: logger);
    final analytics = NoopObservabilityAnalyticsService(
      logger: logger,
      enabled: false,
    );

    await reporter.captureMessage('test');
    await reporter.setUserId('user-1');
    await reporter.setTag('env', 'test');
    await analytics.track('test_event');
    await analytics.identify('user-1');
    await analytics.reset();
  });
}
