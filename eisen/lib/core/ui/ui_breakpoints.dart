import 'package:flutter/widgets.dart';

bool isCompact(Size s) => s.width < 360 || s.height < 700;

double tilePadding(Size s) => isCompact(s) ? 6 : 10;

MediaQuery clampTreemapTSF(BuildContext context, {required Widget child}) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaler.scale(1.0).clamp(1.0, 1.2);
  return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clamped)), child: child);
}
