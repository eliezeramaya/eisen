import 'dart:developer' as developer;

import 'package:eisen/core/config/app_config.dart';

abstract interface class AppLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

final class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger({
    required this.config,
  });

  final AppConfig config;

  @override
  void debug(String message) {
    if (!config.enableDebugLogs) return;
    developer.log(message, name: 'eisen.debug');
  }

  @override
  void info(String message) {
    developer.log(message, name: 'eisen.info');
  }

  @override
  void warning(String message) {
    developer.log(message, name: 'eisen.warning', level: 900);
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'eisen.error',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
