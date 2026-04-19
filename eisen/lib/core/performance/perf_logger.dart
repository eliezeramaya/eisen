import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

typedef PerfMetadata = Map<String, Object?>;

class PerfLabels {
  const PerfLabels._();
  static const String initialLoad = 'initial_load';
  static const String matrixLayout = 'matrix_layout';
  static const String taskSort = 'task_sort';
  static const String statsCompute = 'stats_compute';
  static const String syncCycle = 'sync_cycle';
  static const String frame = 'frame_event';
}

class PerfSample {
  const PerfSample({
    required this.label,
    required this.elapsed,
    required this.startedAt,
    this.meta = const <String, Object?>{},
  });

  final String label;
  final Duration elapsed;
  final DateTime startedAt;
  final PerfMetadata meta;

  Map<String, Object?> toJson() => {
        'label': label,
        'elapsedMs': elapsed.inMicroseconds / 1000.0,
        'startedAt': startedAt.toIso8601String(),
        'meta': meta,
      };
}

class PerfLogger {
  PerfLogger._();
  static final PerfLogger instance = PerfLogger._();

  final List<PerfSample> _recent = <PerfSample>[];
  static const int _maxSamples = 120;

  Future<T> measureAsync<T>(
    String label,
    FutureOr<T> Function() action, {
    PerfMetadata meta = const <String, Object?>{},
    void Function(Duration elapsed)? onComplete,
    bool timeline = true,
  }) async {
    final sw = Stopwatch()..start();
    final start = DateTime.now();
    if (timeline) {
      dev.Timeline.startSync(label, arguments: meta);
    }
    try {
      final result = await action();
      return result;
    } finally {
      if (timeline) {
        dev.Timeline.finishSync();
      }
      sw.stop();
      final sample = PerfSample(
        label: label,
        elapsed: sw.elapsed,
        startedAt: start,
        meta: meta,
      );
      _record(sample);
      if (onComplete != null) {
        onComplete(sw.elapsed);
      }
    }
  }

  Future<T> measureInitialLoad<T>(FutureOr<T> Function() action) =>
      measureAsync<T>(PerfLabels.initialLoad, action);

  Future<T> measureMatrixLayout<T>(
    FutureOr<T> Function() action, {
    int? taskCount,
  }) =>
      measureAsync<T>(
        PerfLabels.matrixLayout,
        action,
        meta: taskCount != null ? <String, Object>{'tasks': taskCount} : const {},
      );

  Future<T> measureTaskSort<T>(
    FutureOr<T> Function() action, {
    int? sampleSize,
  }) =>
      measureAsync<T>(
        PerfLabels.taskSort,
        action,
        meta:
            sampleSize != null ? <String, Object>{'sampleSize': sampleSize} : const {},
      );

  Future<T> measureStats<T>(
    FutureOr<T> Function() action, {
    int? taskCount,
  }) =>
      measureAsync<T>(
        PerfLabels.statsCompute,
        action,
        meta: taskCount != null ? <String, Object>{'tasks': taskCount} : const {},
      );

  Future<T> measureSync<T>(
    FutureOr<T> Function() action, {
    int? outgoing,
    int? incoming,
  }) =>
      measureAsync<T>(
        PerfLabels.syncCycle,
        action,
        meta: <String, Object?>{
          if (outgoing != null) 'outgoing': outgoing,
          if (incoming != null) 'incoming': incoming,
        },
      );

  void record(
    String label,
    Duration duration, {
    PerfMetadata meta = const <String, Object?>{},
    DateTime? startedAt,
  }) {
    final sample = PerfSample(
      label: label,
      elapsed: duration,
      startedAt: startedAt ?? DateTime.now().subtract(duration),
      meta: meta,
    );
    _record(sample);
  }

  void logFrameEvent({
    String label = PerfLabels.frame,
    double? budgetMs,
    PerfMetadata meta = const <String, Object?>{},
  }) {
    final now = DateTime.now();
    final args = <String, Object?>{
      'ts': now.millisecondsSinceEpoch,
      if (budgetMs != null) 'budgetMs': budgetMs,
      ...meta,
    };
    dev.Timeline.instantSync(label, arguments: args);
    _record(
      PerfSample(
        label: label,
        elapsed: Duration.zero,
        startedAt: now,
        meta: args,
      ),
    );
  }

  List<PerfSample> recent({int limit = 20}) {
    final end = _recent.length;
    final start = end - limit < 0 ? 0 : end - limit;
    return _recent.sublist(start, end).reversed.toList(growable: false);
  }

  void _record(PerfSample sample) {
    _recent.add(sample);
    if (_recent.length > _maxSamples) {
      _recent.removeRange(0, _recent.length - _maxSamples);
    }
    if (kDebugMode) {
      dev.log(
        'perf_${sample.label}',
        name: 'perf',
        time: sample.startedAt,
        error:
            '${sample.elapsed.inMilliseconds}ms${sample.meta.isEmpty ? '' : ' ${sample.meta}'}',
      );
    }
  }
}
