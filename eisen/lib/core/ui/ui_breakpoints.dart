import 'package:flutter/widgets.dart';

bool isCompact(Size s) => s.width < 360 || s.height < 700;

double tilePadding(Size s) => isCompact(s) ? 6 : 10;

MediaQuery clampTreemapTSF(BuildContext context, {required Widget child}) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaleFactor.clamp(1.0, 1.2);
  return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clamped)), child: child);
}

// Responsive screen classes for matrix tuning
enum ScreenClass { compact, medium, wide }

ScreenClass classifyScreen(Size size) {
  if (size.width < 600) return ScreenClass.compact;
  if (size.width < 1280) return ScreenClass.medium;
  return ScreenClass.wide;
}
