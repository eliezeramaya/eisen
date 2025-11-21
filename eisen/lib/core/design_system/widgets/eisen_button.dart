import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:flutter/material.dart';

enum EisenButtonVariant { primary, text }

class EisenButton extends StatelessWidget {
  const EisenButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  }) : variant = EisenButtonVariant.primary;

  const EisenButton.text({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  }) : variant = EisenButtonVariant.text;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final EisenButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          Padding(
            padding:
                const EdgeInsets.only(right: EisenSpacing.sm),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(cs.onPrimary),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding:
                const EdgeInsets.only(right: EisenSpacing.sm),
            child: Icon(icon, size: 18),
          ),
        Text(label),
      ],
    );

    switch (variant) {
      case EisenButtonVariant.primary:
        return FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: EisenSpacing.lg,
              vertical: EisenSpacing.sm,
            ),
          ),
          child: child,
        );
      case EisenButtonVariant.text:
        return TextButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        );
    }
  }
}
