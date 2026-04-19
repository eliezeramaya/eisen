import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_state.dart';
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
    final cs = theme.colorScheme;
    final accent = _accentForScore(cs, rankedTask.score);
    final locationLabel = rankedTask.task.locationTag == null
        ? null
        : localizedContextTag(context, rankedTask.task.locationTag);

    return EisenCard(
      interactive: true,
      outlined: true,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              cs.surface,
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
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        label: '${(rankedTask.score * 100).round()}%',
                        icon: Icons.auto_awesome_rounded,
                        color: accent,
                      ),
                      if (locationLabel != null)
                        _MetaPill(
                          label: locationLabel,
                          icon: Icons.place_outlined,
                          color: cs.primary,
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.task_alt_rounded, color: accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              rankedTask.task.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (rankedTask.task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rankedTask.task.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
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
                backgroundColor: accent.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
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
                ),
                _InfoLabel(
                  icon: Icons.schedule_rounded,
                  text: '${rankedTask.task.minutes} min',
                ),
                if (rankedTask.distanceMeters != null)
                  _InfoLabel(
                    icon: Icons.near_me_outlined,
                    text: _formatDistance(rankedTask.distanceMeters!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rankedTask.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentForScore(ColorScheme cs, double score) {
    if (score >= 0.72) return cs.primary;
    if (score >= 0.48) return cs.tertiary;
    return cs.secondary;
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
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
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
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
