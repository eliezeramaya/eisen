import 'dart:typed_data';

import 'package:eisen/features/atlas/application/atlas_export_write_result.dart';

class AtlasExportWriter {
  const AtlasExportWriter();

  Future<AtlasExportWriteResult> writePng({
    required Uint8List bytes,
    required String filename,
  }) async {
    validateAtlasExportWriteInput(bytes: bytes, filename: filename);
    throw const AtlasExportWriteException(
      'La plataforma actual no soporta guardar exportaciones de Atlas.',
    );
  }
}
