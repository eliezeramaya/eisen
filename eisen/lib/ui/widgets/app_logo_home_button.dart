import 'package:eisen/features/eisen_matrix/presentation/controllers/matrix_controller.dart';
import 'package:eisen/features/eisen_matrix/presentation/controllers/treemap_viewport_controller.dart';
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
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final label = isEs ? 'Inicio' : 'Home';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox.expand(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(matrixControllerProvider.notifier).resetHomeView();
                ref.read(treemapViewportControllerProvider.notifier).reset();
                GoRouter.of(context).go('/matrix');
              },
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
