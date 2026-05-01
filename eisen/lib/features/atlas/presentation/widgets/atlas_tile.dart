import 'package:eisen/features/atlas/application/atlas_animation_controller.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_visual_encoding.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_group_header.dart';
import 'package:flutter/material.dart';

class AtlasTile extends StatefulWidget {
  const AtlasTile({
    super.key,
    required this.node,
    required this.size,
    required this.isSelected,
    required this.isFocused,
    required this.onTap,
    required this.onLongPress,
  });

  final AtlasNode node;
  final Size size;
  final bool isSelected;
  final bool isFocused;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<AtlasTile> createState() => _AtlasTileState();
}

class _AtlasTileState extends State<AtlasTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final theme = Theme.of(context);

    if (node.type == AtlasNodeType.group) {
      return _InteractiveShell(
        onHover: (value) => setState(() => _hovered = value),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: AtlasAnimationTokens.tile,
          curve: AtlasAnimationTokens.curve,
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: _hovered ? 0.54 : 0.34,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: _hovered ? 0.88 : 0.58,
              ),
            ),
          ),
          child: widget.size.width < 80 || widget.size.height < 26
              ? const SizedBox.shrink()
              : AtlasGroupHeader(label: node.label, weight: node.weight),
        ),
      );
    }

    final task = node.task;
    if (task == null) return const SizedBox.shrink();

    final encoding = resolveAtlasVisualEncoding(
      task: task,
      theme: theme,
      isFocused: widget.isFocused,
    );
    final showFullText = widget.size.width >= 92 && widget.size.height >= 52;
    final showShortText = widget.size.width >= 60 && widget.size.height >= 36;
    final onlyBlock = widget.size.width < 36 || widget.size.height < 24;
    final borderWidth = widget.isSelected
        ? 2.4
        : encoding.showConfidenceBorder
            ? 1.6
            : 0.8;

    return _InteractiveShell(
      onHover: (value) => setState(() => _hovered = value),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        duration: AtlasAnimationTokens.tile,
        curve: AtlasAnimationTokens.curve,
        scale: widget.isSelected ? 1.015 : (_hovered ? 1.008 : 1),
        child: AnimatedContainer(
          duration: AtlasAnimationTokens.tile,
          curve: AtlasAnimationTokens.curve,
          padding: const EdgeInsets.all(7),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: encoding.showFocusGlow
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.32),
                      blurRadius: 16,
                      spreadRadius: 1.5,
                    ),
                  ]
                : const [],
          ),
          decoration: BoxDecoration(
            color: encoding.fillColor.withValues(alpha: encoding.opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: encoding.borderColor, width: borderWidth),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: onlyBlock
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showFullText || showShortText)
                      Expanded(
                        child: Text(
                          showFullText ? task.title : _shortLabel(task.title),
                          maxLines: showFullText ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: encoding.labelColor,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                    if (showFullText)
                      Row(
                        children: [
                          Text(
                            'P${task.priority}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: encoding.labelColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.minutes}m',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: encoding.labelColor.withValues(alpha: 0.9),
                            ),
                          ),
                          if (widget.isFocused) ...[
                            const Spacer(),
                            Icon(
                              Icons.bolt,
                              size: 13,
                              color: encoding.labelColor,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  String _shortLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 12) return trimmed;
    return '${trimmed.substring(0, 11)}…';
  }
}

class _InteractiveShell extends StatelessWidget {
  const _InteractiveShell({
    required this.child,
    required this.onHover,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        child: child,
      ),
    );
  }
}
