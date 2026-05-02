import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class AtlasExportPixelRatio {
  const AtlasExportPixelRatio._();

  static const fast = 2.0;
  static const standard = 3.0;
  static const high = 4.0;

  static const min = 1.0;
  static const max = high;
}

class AtlasExportException implements Exception {
  const AtlasExportException(this.message);

  final String message;

  @override
  String toString() => 'AtlasExportException: $message';
}

class AtlasExportService {
  const AtlasExportService();

  Future<Uint8List> exportBoundaryToPng({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = AtlasExportPixelRatio.standard,
  }) async {
    if (!_isValidPixelRatio(pixelRatio)) {
      throw const AtlasExportException(
        'La resolución de exportación no es válida.',
      );
    }

    final context = repaintBoundaryKey.currentContext;
    if (context == null) {
      throw const AtlasExportException(
        'Atlas no está listo para exportarse.',
      );
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw const AtlasExportException(
        'El área de exportación no es un RepaintBoundary válido.',
      );
    }

    if (renderObject.debugNeedsPaint) {
      throw const AtlasExportException(
        'Intenta de nuevo cuando el mapa termine de renderizar.',
      );
    }

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null || byteData.lengthInBytes == 0) {
      throw const AtlasExportException(
        'No se pudieron generar bytes PNG para Atlas.',
      );
    }

    return byteData.buffer.asUint8List();
  }

  bool _isValidPixelRatio(double value) {
    return value.isFinite &&
        value >= AtlasExportPixelRatio.min &&
        value <= AtlasExportPixelRatio.max;
  }
}
