import 'package:eisen/core/theme/ui_tokens.dart';
import 'package:flutter/material.dart';

/// A task tile widget with built-in accessibility support.
///
/// Features:
/// - Semantic labels for screen readers
/// - Focus indication for keyboard navigation
/// - High contrast support
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.selected = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Task: $title, $subtitle',
      button: true,
      enabled: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _HoverScale(
          child: Focus(
            child: Builder(
              builder: (context) {
                final focusNode = Focus.of(context);
                final isFocused = focusNode.hasFocus;

                return AnimatedContainer(
                  duration: kAnimFast,
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(kRadius),
                    border: isFocused
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(kRadius),
                      focusColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      hoverColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: ListTile(
                        title: Text(title, style: theme.textTheme.titleMedium),
                        subtitle: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        selected: selected,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: kAnimFast,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
