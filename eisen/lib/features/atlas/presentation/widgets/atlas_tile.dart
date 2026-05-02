import 'package:eisen/features/atlas/application/atlas_animation_controller.dart';
import 'package:eisen/features/atlas/domain/atlas_node.dart';
import 'package:eisen/features/atlas/domain/atlas_semantic_zoom.dart';
import 'package:eisen/features/atlas/domain/atlas_visual_encoding.dart';
import 'package:eisen/features/atlas/presentation/widgets/atlas_group_header.dart';
import 'package:flutter/material.dart';

class AtlasTile extends StatefulWidget {
  const AtlasTile({
    super.key,
    required this.node,
    required this.size,
    required this.minReadableSize,
    required this.compactMode,
    required this.enableHover,
    this.exportMode = false,
    this.semanticLevel = AtlasSemanticLevel.task,
    required this.isSelected,
    required this.isFocused,
    this.isInsightHighlighted = false,
    required this.onTap,
    required this.onLongPress,
  });

  final AtlasNode node;
  final Size size;
  final Size minReadableSize;
  final bool compactMode;
  final bool enableHover;
  final bool exportMode;
  final AtlasSemanticLevel semanticLevel;
  final bool isSelected;
  final bool isFocused;
  final bool isInsightHighlighted;
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
    final hovered = widget.exportMode ? false : _hovered;

    if (node.type == AtlasNodeType.group) {
      return _InteractiveShell(
        enableHover: widget.enableHover,
        onHover: (value) => setState(() => _hovered = value),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: AtlasAnimationTokens.tile,
          curve: AtlasAnimationTokens.curve,
          padding: EdgeInsets.fromLTRB(
            widget.compactMode ? 6 : 8,
            widget.compactMode ? 4 : 5,
            widget.compactMode ? 6 : 8,
            4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: hovered ? 0.54 : 0.34,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: hovered ? 0.88 : 0.58,
              ),
            ),
          ),
          child: widget.size.width < widget.minReadableSize.width ||
                  widget.size.height < 26
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
    final showFullText = widget.semanticLevel.showRichTaskContent &&
        !widget.compactMode &&
        widget.size.width >= widget.minReadableSize.width + 20 &&
        widget.size.height >= widget.minReadableSize.height + 8;
    final showShortText = widget.size.width >= widget.minReadableSize.width &&
        widget.size.height >= widget.minReadableSize.height;
    final onlyBlock = widget.size.width < 36 || widget.size.height < 24;
    final borderWidth = widget.isSelected
        ? 2.4
        : widget.isInsightHighlighted
            ? 2.0
            : encoding.showConfidenceBorder
                ? 1.6
                : 0.8;
    final borderColor = widget.isSelected
        ? theme.colorScheme.primary
        : widget.isInsightHighlighted
            ? theme.colorScheme.tertiary
            : encoding.borderColor;

    return _InteractiveShell(
      enableHover: widget.enableHover,
      onHover: (value) => setState(() => _hovered = value),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        duration:
            widget.compactMode ? Duration.zero : AtlasAnimationTokens.tile,
        curve: AtlasAnimationTokens.curve,
        scale: widget.compactMode
            ? 1
            : widget.isSelected
                ? 1.015
                : (hovered ? 1.008 : 1),
        child: AnimatedContainer(
          duration:
              widget.compactMode ? Duration.zero : AtlasAnimationTokens.tile,
          curve: AtlasAnimationTokens.curve,
          padding: EdgeInsets.all(widget.compactMode ? 5 : 7),
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
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: hovered && !widget.compactMode
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
                          showFullText || widget.compactMode
                              ? task.title
                              : _shortLabel(task.title),
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
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: encoding.labelColor.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Foco',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: encoding.labelColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (widget.isInsightHighlighted &&
                              widget.size.width >= 128) ...[
                            const Spacer(),
                            Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: encoding.labelColor.withValues(
                                alpha: 0.88,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (widget.compactMode && widget.isInsightHighlighted)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (widget.compactMode && widget.isFocused)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: encoding.labelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
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
    required this.enableHover,
    required this.onHover,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final bool enableHover;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: enableHover ? (_) => onHover(true) : null,
      onExit: enableHover ? (_) => onHover(false) : null,
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
