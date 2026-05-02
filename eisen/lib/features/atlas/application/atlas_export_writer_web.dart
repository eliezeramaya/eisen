// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:eisen/features/atlas/application/atlas_export_write_result.dart';

class AtlasExportWriter {
  const AtlasExportWriter();

  Future<AtlasExportWriteResult> writePng({
    required Uint8List bytes,
    required String filename,
  }) async {
    validateAtlasExportWriteInput(bytes: bytes, filename: filename);

    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return AtlasExportWriteResult(
      filename: filename,
      bytes: bytes.length,
      destination: AtlasExportWriteDestination.webDownload,
    );
  }
}
