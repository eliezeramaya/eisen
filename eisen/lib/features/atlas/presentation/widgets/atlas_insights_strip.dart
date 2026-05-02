import 'package:eisen/features/atlas/domain/atlas_insight.dart';
import 'package:flutter/material.dart';

class AtlasInsightsStrip extends StatelessWidget {
  const AtlasInsightsStrip({
    super.key,
    required this.insights,
    required this.compact,
    this.onInsightSelected,
    this.onActionSelected,
  });

  final List<AtlasInsight> insights;
  final bool compact;
  final ValueChanged<AtlasInsight>? onInsightSelected;
  final void Function(AtlasInsight insight, AtlasInsightAction action)?
      onActionSelected;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final children = [
      for (final insight in insights)
        _InsightPill(
          insight: insight,
          compact: compact,
          onTap: onInsightSelected == null
              ? null
              : () => onInsightSelected?.call(insight),
          onActionSelected: onActionSelected == null
              ? null
              : (action) => onActionSelected?.call(insight, action),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: compact
          ? SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => SizedBox(
                  width: 260,
                  child: children[index],
                ),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final child in children)
                  SizedBox(
                    width: 280,
                    child: child,
                  ),
              ],
            ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.insight,
    required this.compact,
    this.onTap,
    this.onActionSelected,
  });

  final AtlasInsight insight;
  final bool compact;
  final VoidCallback? onTap;
  final ValueChanged<AtlasInsightAction>? onActionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _toneFor(theme, insight.priority);
    return Material(
      color: tone.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tone.border),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(insight.kind), size: 18, color: tone.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        insight.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: tone.foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight.message,
                        maxLines: compact ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tone.foreground.withValues(alpha: 0.84),
                          height: 1.15,
                        ),
                      ),
                      if (insight.actions.isNotEmpty &&
                          onActionSelected != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final action
                                in insight.actions.take(compact ? 1 : 2))
                              _InsightActionButton(
                                action: action,
                                tone: tone,
                                onPressed: () => onActionSelected?.call(action),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightActionButton extends StatelessWidget {
  const _InsightActionButton({
    required this.action,
    required this.tone,
    required this.onPressed,
  });

  final AtlasInsightAction action;
  final _InsightTone tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: tone.border),
      backgroundColor: tone.foreground.withValues(alpha: 0.08),
      label: Text(action.label),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone.foreground,
            fontWeight: FontWeight.w800,
          ),
      onPressed: onPressed,
    );
  }
}

_InsightTone _toneFor(ThemeData theme, AtlasInsightPriority priority) {
  return switch (priority) {
    AtlasInsightPriority.high => _InsightTone(
        background: theme.colorScheme.errorContainer.withValues(alpha: 0.42),
        foreground: theme.colorScheme.onErrorContainer,
        border: theme.colorScheme.error.withValues(alpha: 0.26),
      ),
    AtlasInsightPriority.medium => _InsightTone(
        background:
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.42),
        foreground: theme.colorScheme.onSecondaryContainer,
        border: theme.colorScheme.secondary.withValues(alpha: 0.24),
      ),
    AtlasInsightPriority.low => _InsightTone(
        background:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        foreground: theme.colorScheme.onSurfaceVariant,
        border: theme.colorScheme.outlineVariant,
      ),
  };
}

IconData _iconFor(AtlasInsightKind kind) {
  return switch (kind) {
    AtlasInsightKind.overload => Icons.priority_high,
    AtlasInsightKind.focusOpportunity => Icons.center_focus_strong,
    AtlasInsightKind.classificationReview => Icons.rule,
    AtlasInsightKind.stalePlan => Icons.call_split,
    AtlasInsightKind.quadrantImbalance => Icons.balance,
  };
}

class _InsightTone {
  const _InsightTone({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
