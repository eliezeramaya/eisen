import 'package:flutter/material.dart';
import 'package:eisen/core/theme/ui_tokens.dart';

class TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const TaskTile({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _HoverScale(
        child: AnimatedContainer(
          duration: kAnimFast,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(kRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});
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
