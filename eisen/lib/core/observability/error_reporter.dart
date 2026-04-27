import 'package:eisen/core/observability/app_logger.dart';

abstract interface class ErrorReporter {
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  });

  Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? context,
  });

  Future<void> setUserId(String? userId);
  Future<void> setTag(String key, String value);
}

final class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter({
    required this.logger,
  });

  final AppLogger logger;

  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    logger.error(
      'Captured local exception',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    logger.warning(message);
  }

  @override
  Future<void> setTag(String key, String value) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}
