import 'package:eisen/core/config/app_config.dart';
import 'package:eisen/core/observability/analytics_service.dart';
import 'package:eisen/core/observability/app_logger.dart';
import 'package:eisen/core/observability/error_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);

final appLoggerProvider = Provider<AppLogger>((ref) {
  return ConsoleAppLogger(config: ref.watch(appConfigProvider));
});

final errorReporterProvider = Provider<ErrorReporter>((ref) {
  return NoopErrorReporter(logger: ref.watch(appLoggerProvider));
});

final observabilityAnalyticsProvider =
    Provider<ObservabilityAnalyticsService>((ref) {
  final config = ref.watch(appConfigProvider);
  return NoopObservabilityAnalyticsService(
    logger: ref.watch(appLoggerProvider),
    enabled: config.isAnalyticsConfigured,
  );
});
