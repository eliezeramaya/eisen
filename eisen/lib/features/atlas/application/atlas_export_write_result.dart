enum AtlasExportWriteDestination {
  documents,
  webDownload,
  unsupported,
}

class AtlasExportWriteException implements Exception {
  const AtlasExportWriteException(this.message);

  final String message;

  @override
  String toString() => 'AtlasExportWriteException: $message';
}

class AtlasExportWriteResult {
  const AtlasExportWriteResult({
    required this.filename,
    required this.bytes,
    required this.destination,
    this.filePath,
  });

  final String filename;
  final int bytes;
  final AtlasExportWriteDestination destination;
  final String? filePath;

  bool get downloaded => destination == AtlasExportWriteDestination.webDownload;

  bool get savedToFile =>
      destination == AtlasExportWriteDestination.documents && filePath != null;
}

void validateAtlasExportWriteInput({
  required List<int> bytes,
  required String filename,
}) {
  if (bytes.isEmpty) {
    throw const AtlasExportWriteException(
      'No se pudo guardar Atlas porque el PNG está vacío.',
    );
  }

  final normalized = filename.trim();
  if (normalized.isEmpty ||
      normalized.contains('/') ||
      normalized.contains(r'\') ||
      normalized.contains(':')) {
    throw const AtlasExportWriteException(
      'El nombre del archivo de Atlas no es válido.',
    );
  }

  if (!normalized.toLowerCase().endsWith('.png')) {
    throw const AtlasExportWriteException(
      'Atlas solo puede exportarse como PNG.',
    );
  }
}
