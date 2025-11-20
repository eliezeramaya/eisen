import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:flutter/material.dart';

class EisenCard extends StatelessWidget {
  const EisenCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.outlined = false,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool outlined;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.eisenSurface;
    final borderColor =
        outlined ? cs.eisenBorderSubtle : Colors.transparent;
    final radius = BorderRadius.circular(EisenRadius.lg);

    Widget content = Container(
      margin: margin,
      padding: padding ??
          const EdgeInsets.all(EisenSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: outlined ? 1 : 0),
        boxShadow: interactive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: child,
    );

    if (interactive || onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

