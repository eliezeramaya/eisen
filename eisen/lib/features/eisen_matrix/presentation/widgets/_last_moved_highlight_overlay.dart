import 'package:eisen/core/ui/ui_tokens.dart';
import 'package:eisen/features/eisen_matrix/domain/treemap_layout.dart';
import 'package:flutter/material.dart';

class LastMovedHighlightOverlay extends StatelessWidget {
  const LastMovedHighlightOverlay({
    super.key,
    required this.id,
    required this.layout,
    required this.rectMap,
    required this.size,
  });

  final String id;
  final List<TreemapRect> layout;
  final Map<String, Rect> rectMap;
  final Size size;

  @override
  Widget build(BuildContext context) {
    Rect? rect01 = rectMap[id];
    if (rect01 == null && layout.isNotEmpty) {
      final tr = layout
          .firstWhere((e) => e.task.id == id, orElse: () => layout.first);
      rect01 = tr.rect01;
    }
    if (rect01 == null) {
      return const SizedBox.shrink();
    }

    final rect = Rect.fromLTWH(
      rect01.left * size.width,
      rect01.top * size.height,
      rect01.width * size.width,
      rect01.height * size.height,
    ).deflate(2);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.05, end: 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(UiTokens.tileRadius + 1),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.65),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

