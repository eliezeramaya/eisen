import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App logo that behaves as a Home button.
///
/// When tapped, it resets the matrix view to the initial 4‑quadrant state
/// and navigates to the matrix home route ('/matrix').
class AppLogoHomeButton extends ConsumerWidget {
  const AppLogoHomeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Ensure matrix returns to the initial full‑matrix view.
        ref.read(matrixControllerProvider.notifier).resetHomeView();
        // Navigate to the matrix home route.
        GoRouter.of(context).go('/matrix');
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.grid_view_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
