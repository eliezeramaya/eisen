import 'package:eisen/core/observability/app_logger.dart';

abstract interface class ObservabilityAnalyticsService {
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  });

  Future<void> reset();
}

final class NoopObservabilityAnalyticsService
    implements ObservabilityAnalyticsService {
  const NoopObservabilityAnalyticsService({
    required this.logger,
    required this.enabled,
  });

  final AppLogger logger;
  final bool enabled;

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) async {
    if (!enabled) return;
    logger.debug('analytics identify: traits=${traits.keys.join(',')}');
  }

  @override
  Future<void> reset() async {
    if (!enabled) return;
    logger.debug('analytics reset');
  }

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    if (!enabled) return;
    logger.debug(
        'analytics event: $eventName props=${properties.keys.join(',')}');
  }
}
