import 'dart:io';
import 'dart:typed_data';

import 'package:eisen/features/atlas/application/atlas_export_write_result.dart';
import 'package:path_provider/path_provider.dart';

typedef AtlasExportDirectoryProvider = Future<Directory> Function();

class AtlasExportWriter {
  const AtlasExportWriter({
    AtlasExportDirectoryProvider? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider = documentsDirectoryProvider;

  final AtlasExportDirectoryProvider? _documentsDirectoryProvider;

  Future<AtlasExportWriteResult> writePng({
    required Uint8List bytes,
    required String filename,
  }) async {
    validateAtlasExportWriteInput(bytes: bytes, filename: filename);

    final directory = await (_documentsDirectoryProvider?.call() ??
        getApplicationDocumentsDirectory());
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);

    return AtlasExportWriteResult(
      filename: filename,
      bytes: bytes.length,
      destination: AtlasExportWriteDestination.documents,
      filePath: file.path,
    );
  }
}
