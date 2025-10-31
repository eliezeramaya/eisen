import 'package:eisen/core/responsive/layout_tokens.dart';
import 'package:flutter/material.dart';

class ZenCompletionDialog extends StatelessWidget {
  const ZenCompletionDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + AppSpacing.xs, // 32 + 8 = 40
        vertical: AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Momento Zen', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Cada animación es una respiración;\ncada color, una emoción;\ncada tarea completada, un instante de calma.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
