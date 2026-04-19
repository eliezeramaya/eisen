// ignore_for_file: sort_constructors_first

import 'dart:async';
import 'dart:math' as math;

import 'package:eisen/core/constants/layout_constants.dart';
import 'package:eisen/core/workers/worker_models.dart';
import 'package:eisen/features/eisen_matrix/domain/bandit_service.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/eisen_treemap_hybrid.dart';
import 'package:eisen/features/eisen_matrix/domain/layout/layout_config.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Serializable request for the matrix layout worker.
///
/// DTO-friendly so it can safely cross isolate boundaries via `compute`.
class MatrixLayoutRequest {
  const MatrixLayoutRequest({
    required this.tasks,
    this.zoom,
    this.viewport,
    this.compactDensity = false,
    this.minAreaNormalized,
    this.cache,
    this.banditSeed = 42,
    this.hybridConfig,
    this.minTileSizePx,
  });

  final List<TaskIsolateSnapshot> tasks;
  final Quadrant? zoom;
  final MatrixViewportSnapshot? viewport;
  final bool compactDensity;
  final double? minAreaNormalized;
  final MatrixLayoutCachePayload? cache;
  final int banditSeed;
  final LayoutConfig? hybridConfig;
  final double? minTileSizePx;

  Map<String, Object?> toJson() => {
        'tasks': tasks.map((t) => t.toJson()).toList(growable: false),
        'zoom': zoom?.index,
        'viewport': viewport?.toJson(),
        'compactDensity': compactDensity,
        'minAreaNormalized': minAreaNormalized,
        'cache': cache?.toJson(),
        'banditSeed': banditSeed,
        'minTileSizePx': minTileSizePx,
        'hybridConfig': hybridConfig == null
            ? null
            : {
                'topKPerQuadrant': hybridConfig!.topKPerQuadrant,
                'minAreaNormalized': hybridConfig!.minAreaNormalized,
                'gamma': hybridConfig!.gamma,
                'quadrantPadding': hybridConfig!.quadrantPadding,
              },
      };

  factory MatrixLayoutRequest.fromJson(Map<String, Object?> json) {
    final tasksJson = json['tasks'];
    final tasks = tasksJson is List
        ? tasksJson
            .whereType<Map<String, Object?>>()
            .map(TaskIsolateSnapshot.fromJson)
            .toList(growable: false)
        : const <TaskIsolateSnapshot>[];

    final viewportJson = json['viewport'];
    final cacheJson = json['cache'];
    final zoomIndex = json['zoom'] as int?;
    final hybridJson = json['hybridConfig'] as Map<String, Object?>?;
    final config = hybridJson == null
        ? null
        : LayoutConfig(
            topKPerQuadrant: hybridJson['topKPerQuadrant'] as int? ?? 20,
            minAreaNormalized:
                (hybridJson['minAreaNormalized'] as num?)?.toDouble() ??
                    0.00004,
            gamma: (hybridJson['gamma'] as num?)?.toDouble() ?? 1.0,
            quadrantPadding:
                (hybridJson['quadrantPadding'] as num?)?.toDouble() ?? 0.012,
          );

    return MatrixLayoutRequest(
      tasks: tasks,
      zoom: zoomIndex == null ||
              zoomIndex < 0 ||
              zoomIndex >= Quadrant.values.length
          ? null
          : Quadrant.values[zoomIndex],
      viewport: viewportJson is Map<String, Object?>
          ? MatrixViewportSnapshot.fromJson(viewportJson)
          : null,
      compactDensity: json['compactDensity'] as bool? ?? false,
      minAreaNormalized: (json['minAreaNormalized'] as num?)?.toDouble(),
      cache: cacheJson is Map<String, Object?>
          ? MatrixLayoutCachePayload.fromJson(cacheJson)
          : null,
      banditSeed: json['banditSeed'] as int? ?? 42,
      hybridConfig: config,
      minTileSizePx: (json['minTileSizePx'] as num?)?.toDouble(),
    );
  }
}

/// Cache snapshot that can be serialized/deserialized across isolates.
class MatrixLayoutCachePayload {
  const MatrixLayoutCachePayload({
    this.lastWeight = const <String, double>{},
    this.lastRect = const <String, MatrixRectDto>{},
    this.lastRank = const <String, int>{},
  });

  final Map<String, double> lastWeight;
  final Map<String, MatrixRectDto> lastRect;
  final Map<String, int> lastRank;

  Map<String, Object?> toJson() => {
        'lastWeight': lastWeight,
        'lastRect': lastRect.map(
          (key, value) => MapEntry<String, Object>(key, value.toJson()),
        ),
        'lastRank': lastRank,
      };

  factory MatrixLayoutCachePayload.fromJson(Map<String, Object?> json) {
    final rectJson = json['lastRect'];
    final rects = <String, MatrixRectDto>{};
    if (rectJson is Map) {
      rectJson.forEach((key, value) {
        if (key is String && value is Map<String, Object?>) {
          rects[key] = MatrixRectDto.fromJson(value);
        }
      });
    }
    final weightJson = json['lastWeight'];
    final rankJson = json['lastRank'];
    final weights = weightJson is Map
        ? weightJson.map((key, value) => MapEntry<String, double>(
              key as String,
              (value as num).toDouble(),
            ))
        : const <String, double>{};
    final ranks = rankJson is Map
        ? rankJson.map((key, value) => MapEntry<String, int>(
              key as String,
              value as int,
            ))
        : const <String, int>{};

    return MatrixLayoutCachePayload(
      lastWeight: weights,
      lastRect: rects,
      lastRank: ranks,
    );
  }

  LayoutCache toLayoutCache() {
    final cache = LayoutCache();
    cache.lastWeight.addAll(lastWeight);
    cache.lastRank.addAll(lastRank);
    lastRect.forEach((key, value) {
      cache.lastRect[key] = value.toRect();
    });
    return cache;
  }

  factory MatrixLayoutCachePayload.fromLayoutCache(LayoutCache cache) {
    return MatrixLayoutCachePayload(
      lastWeight: Map<String, double>.from(cache.lastWeight),
      lastRect: cache.lastRect.map((key, value) =>
          MapEntry<String, MatrixRectDto>(key, MatrixRectDto.fromRect(value))),
      lastRank: Map<String, int>.from(cache.lastRank),
    );
  }
}

class MatrixLayoutTile {
  const MatrixLayoutTile({
    required this.id,
    required this.quadrant,
    required this.rect01,
    required this.canvasRect,
    this.stackIds = const <String>[],
  });

  final String id;
  final Quadrant quadrant;
  final MatrixRectDto rect01;
  final MatrixRectDto canvasRect;
  final List<String> stackIds;

  Map<String, Object> toJson() => {
        'id': id,
        'quadrant': quadrant.index,
        'rect01': rect01.toJson(),
        'canvasRect': canvasRect.toJson(),
        'stackIds': stackIds,
      };

  factory MatrixLayoutTile.fromJson(Map<String, Object?> json) =>
      MatrixLayoutTile(
        id: json['id'] as String,
        quadrant: Quadrant.values[
            (json['quadrant'] as int).clamp(0, Quadrant.values.length - 1)],
        rect01: MatrixRectDto.fromJson(json['rect01']! as Map<String, Object?>),
        canvasRect:
            MatrixRectDto.fromJson(json['canvasRect']! as Map<String, Object?>),
        stackIds:
            (json['stackIds'] as List?)?.cast<String>() ?? const <String>[],
      );
}

class MatrixLayoutResponse {
  const MatrixLayoutResponse({
    required this.tiles,
    required this.cache,
    required this.elapsedMs,
    required this.taskCount,
  });

  final List<MatrixLayoutTile> tiles;
  final MatrixLayoutCachePayload cache;
  final double elapsedMs;
  final int taskCount;

  Map<String, Object?> toJson() => {
        'tiles': tiles.map((t) => t.toJson()).toList(growable: false),
        'cache': cache.toJson(),
        'elapsedMs': elapsedMs,
        'taskCount': taskCount,
      };

  factory MatrixLayoutResponse.fromJson(Map<String, Object?> json) =>
      MatrixLayoutResponse(
        tiles: (json['tiles'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, Object?>>()
            .map(MatrixLayoutTile.fromJson)
            .toList(growable: false),
        cache: MatrixLayoutCachePayload.fromJson(
            json['cache']! as Map<String, Object?>),
        elapsedMs: (json['elapsedMs'] as num).toDouble(),
        taskCount: json['taskCount'] as int,
      );
}

/// Top-level entry point so it can be passed directly to `compute`.
Future<MatrixLayoutResponse> matrixLayoutWorker(
  Map<String, Object?> message,
) async {
  final request = MatrixLayoutRequest.fromJson(message);
  final cache = request.cache?.toLayoutCache() ?? LayoutCache();
  final bandit = BanditService(seed: request.banditSeed);
  final tasks = request.tasks.map((t) => t.toDomain()).toList(growable: false);

  final sw = Stopwatch()..start();
  final minArea01 = _resolveMinArea(request);
  final layout = request.hybridConfig != null
      ? _runHybridLayout(
          tasks,
          request.hybridConfig!,
          request.zoom,
          minArea01 ?? request.minAreaNormalized,
        )
      : computeStableLayout(
          tasks,
          zoom: request.zoom,
          cache: cache,
          bandit: bandit,
          minTileArea01: minArea01,
        );

  final viewport = request.viewport;
  final tiles = layout
      .map(
        (rect) => MatrixLayoutTile(
          id: rect.task.id,
          quadrant: rect.task.quadrant,
          rect01: MatrixRectDto.fromRect(rect.rect01),
          canvasRect: viewport == null
              ? MatrixRectDto.fromRect(rect.rect01)
              : _toCanvasRect(rect.rect01, viewport),
          stackIds: rect.stackChildren.map((t) => t.id).toList(growable: false),
        ),
      )
      .toList(growable: false);

  sw.stop();

  final response = MatrixLayoutResponse(
    tiles: tiles,
    cache: MatrixLayoutCachePayload.fromLayoutCache(cache),
    elapsedMs: sw.elapsedMicroseconds / 1000.0,
    taskCount: tasks.length,
  );

  if (kDebugMode) {
    debugPrint(
        '[MatrixLayoutWorker] tasks=${tasks.length} zoom=${request.zoom?.name ?? 'all'} elapsed=${response.elapsedMs.toStringAsFixed(2)}ms');
  }
  return response;
}

List<TreemapRect> _runHybridLayout(
  List<Task> tasks,
  LayoutConfig config,
  Quadrant? zoom,
  double? minArea01,
) {
  final engine = EisenTreemapHybrid(config);
  if (zoom != null) {
    return engine.layout(tasks, only: zoom, minArea01: minArea01);
  }
  return engine.layout(tasks, minArea01: minArea01);
}

MatrixRectDto _toCanvasRect(
  Rect rect01,
  MatrixViewportSnapshot viewport,
) {
  final base = MatrixRectDto(
    left: rect01.left * viewport.width,
    top: rect01.top * viewport.height,
    width: rect01.width * viewport.width,
    height: rect01.height * viewport.height,
  );
  final scaled = viewport.scale == 1.0 ? base : base.scale(viewport.scale);
  if (viewport.offsetX == 0 && viewport.offsetY == 0) {
    return scaled;
  }
  return scaled.translate(viewport.offsetX, viewport.offsetY);
}

double? _resolveMinArea(MatrixLayoutRequest request) {
  final viewport = request.viewport;
  final tileSizePx =
      request.minTileSizePx ?? LayoutConstants.defaultMinTileSize;
  final minFromViewport = viewport != null && viewport.hasArea
      ? (LayoutConstants.minTileAreaPx(tileSizePx) *
              (request.compactDensity ? 0.7 : 1.0)) /
          (viewport.width * viewport.height)
      : null;
  final cfgMin =
      request.minAreaNormalized ?? request.hybridConfig?.minAreaNormalized;
  if (minFromViewport == null) return cfgMin;
  if (cfgMin == null) {
    return minFromViewport.clamp(0.0, 1.0);
  }
  return math.max(cfgMin, minFromViewport.clamp(0.0, 1.0));
}
