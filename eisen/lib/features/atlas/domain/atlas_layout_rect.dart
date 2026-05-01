import 'package:flutter/widgets.dart';

class AtlasLayoutRect {
  const AtlasLayoutRect({
    required this.nodeId,
    required this.rect,
    required this.depth,
    required this.isLeaf,
  });

  final String nodeId;
  final Rect rect;
  final int depth;
  final bool isLeaf;
}
