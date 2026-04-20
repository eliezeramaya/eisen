import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/tasks/context_aware/application/contextual_treemap_layout.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
import 'package:eisen/features/tasks/context_aware/presentation/contextual_treemap_palette.dart';
import 'package:flutter/material.dart';

class ContextAwareTaskCard extends StatelessWidget {
  const ContextAwareTaskCard({
    super.key,
    required this.rankedTask,
  });

  final RankedContextTask rankedTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final group = inferContextTreemapGroup(rankedTask.task);
    final accent = ContextualTreemapPalette.tileColor(
      rankedTask: rankedTask,
      group: group,
      colorScheme: colorScheme,
      isActiveSection: rankedTask.isHighRelevance,
      isSelected: true,
    );
    final titleColor = ContextualTreemapPalette.textColorFor(accent);
    final bodyColor = ContextualTreemapPalette.mutedTextColorFor(accent);
    final locationLabel = rankedTask.task.locationTag == null
        ? null
        : localizedContextTag(context, rankedTask.task.locationTag);

    return EisenCard(
      outlined: true,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              accent,
              Color.lerp(
                accent,
                ContextualTreemapPalette.surfaceElevated,
                0.7,
              )!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        label: '${(rankedTask.score * 100).round()}%',
                        icon: Icons.auto_awesome_rounded,
                        foregroundColor: titleColor,
                      ),
                      if (locationLabel != null)
                        _MetaPill(
                          label: locationLabel,
                          icon: Icons.place_outlined,
                          foregroundColor: titleColor,
                        ),
                      _MetaPill(
                        label: _groupLabel(context, group),
                        icon: Icons.grid_view_rounded,
                        foregroundColor: titleColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: titleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      rankedTask.task.isBlocked
                          ? Icons.lock_clock_outlined
                          : Icons.task_alt_rounded,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              rankedTask.task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (rankedTask.task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rankedTask.task.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: rankedTask.score.clamp(0.02, 1.0),
                minHeight: 7,
                backgroundColor: titleColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(titleColor),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _InfoLabel(
                  icon: Icons.flag_outlined,
                  text: 'P${rankedTask.task.priority}',
                  color: bodyColor,
                ),
                _InfoLabel(
                  icon: Icons.schedule_rounded,
                  text: '${rankedTask.task.minutes} min',
                  color: bodyColor,
                ),
                if (rankedTask.distanceMeters != null)
                  _InfoLabel(
                    icon: Icons.near_me_outlined,
                    text: _formatDistance(rankedTask.distanceMeters!),
                    color: bodyColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rankedTask.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bodyColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _groupLabel(BuildContext context, ContextTreemapGroup group) {
    return localizedTreemapGroupLabel(context, group);
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.icon,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(
      foregroundColor,
      ContextualTreemapPalette.surfaceElevated,
      0.78,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
