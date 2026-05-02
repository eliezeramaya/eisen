import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/tasks/presentation/add_task_sheet.dart';
import 'package:flutter/material.dart';

class MatrixNavBarItem extends StatelessWidget {
  const MatrixNavBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Quick quadrant add removed in favor of global FAB

Future<void> openAddTaskSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddTaskSheet(),
  );
}


class MatrixBottomActionBar extends StatelessWidget {
  const MatrixBottomActionBar({
    required this.onNew,
    required this.onNewInQuadrant,
    this.minimap,
    this.highScale = false,
  });
  final VoidCallback onNew;
  final void Function(Quadrant q) onNewInQuadrant;
  final Widget? minimap;
  // AppTextScale applied: adjusts paddings for high scales
  final bool highScale;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final entryLabel = isEs ? 'Entrada' : 'Entry';
    return SafeArea(
      child: Container(
        // Reduce vertical padding to make the bar more compact on mobile
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          // Increase vertical padding slightly when scale is extreme
          vertical: highScale ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hideMinimap = constraints.maxWidth < 560;
            final isNarrow = constraints.maxWidth < 400;

            return SizedBox(
              // More compact height on very narrow screens
              height: isNarrow ? 44 : 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered primary action button (Entrada)
                  Semantics(
                    button: true,
                    enabled: true,
                    label: entryLabel,
                    child: isNarrow
                        // Icon-only CTA on very small widths
                        ? IconButton(
                            onPressed: onNew,
                            tooltip: entryLabel,
                            icon: const Icon(Icons.add),
                          )
                        : FilledButton.icon(
                            onPressed: onNew,
                            icon: const Icon(Icons.add),
                            label: Text(entryLabel),
                          ),
                  ),

                  // Minimap pinned to the right when there's space
                  if (!hideMinimap && minimap != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: minimap!,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
