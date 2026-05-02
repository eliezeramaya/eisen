String atlasExportFilename({
  required DateTime date,
  bool includeTime = false,
}) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  if (!includeTime) {
    return 'eisen-atlas-$year-$month-$day.png';
  }

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return 'eisen-atlas-$year-$month-$day-$hour$minute.png';
}
