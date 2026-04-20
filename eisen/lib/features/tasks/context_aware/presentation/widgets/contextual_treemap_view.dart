import 'dart:math' as math;

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/features/tasks/context_aware/application/contextual_treemap_layout.dart';
import 'package:eisen/features/tasks/context_aware/domain/context_aware_task_scoring.dart';
import 'package:eisen/features/tasks/context_aware/presentation/contextual_treemap_palette.dart';
import 'package:flutter/material.dart';

class ContextualTreemapView extends StatelessWidget {
  const ContextualTreemapView({
    super.key,
    required this.layout,
    required this.selectedTaskId,
    required this.onTaskSelected,
    this.compact = false,
  });

  final ContextTreemapLayout layout;
  final String? selectedTaskId;
  final ValueChanged<RankedContextTask> onTaskSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextualTreemapPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(EisenRadius.lg + 6),
        border: Border.all(color: ContextualTreemapPalette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EisenRadius.lg + 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final sectionGap = compact ? 8.0 : 12.0;
            final outerPadding = compact ? 10.0 : 14.0;

            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ContextualTreemapPalette.background,
                          ContextualTreemapPalette.surfaceElevated,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                for (final section in layout.sections)
                  _AnimatedRect(
                    rect: _deflateRect(
                      _rectFromNormalized(section.rect01, width, height),
                      sectionGap,
                    ),
                    child: _ContextSection(
                      section: section,
                      selectedTaskId: selectedTaskId,
                      compact: compact,
                      padding: outerPadding,
                      onTaskSelected: onTaskSelected,
                      colorScheme: colorScheme,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({
    required this.section,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.compact,
    required this.padding,
    required this.colorScheme,
  });

  final ContextTreemapSectionLayout section;
  final String? selectedTaskId;
  final ValueChanged<RankedContextTask> onTaskSelected;
  final bool compact;
  final double padding;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final groupColor = ContextualTreemapPalette.groupBaseColor(
      section.group,
      colorScheme,
    );
    final headerHeight = compact ? 36.0 : 42.0;
    final headerLabel = localizedTreemapGroupLabel(context, section.group);
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullRect = Offset.zero & constraints.biggest;
        final innerRect = Rect.fromLTWH(
          padding,
          headerHeight + padding,
          math.max(0, fullRect.width - padding * 2),
          math.max(0, fullRect.height - headerHeight - padding * 2),
        );

        return Semantics(
          container: true,
          label: isEs
              ? 'Grupo $headerLabel, ${section.tiles.length} tareas${section.isActive ? ', contexto activo' : ''}'
              : '$headerLabel group, ${section.tiles.length} tasks${section.isActive ? ', active context' : ''}',
          child: Container(
            decoration: BoxDecoration(
              color: section.isActive
                  ? ContextualTreemapPalette.surface
                  : ContextualTreemapPalette.surfaceElevated,
              borderRadius: BorderRadius.circular(EisenRadius.lg + 2),
              border: Border.all(
                color: section.isActive
                    ? ContextualTreemapPalette.primary
                    : ContextualTreemapPalette.border,
                width: section.isActive ? 1.6 : 1,
              ),
              boxShadow: section.isActive
                  ? [
                      BoxShadow(
                        color: ContextualTreemapPalette.primary
                            .withValues(alpha: 0.14),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: padding,
                  top: padding,
                  right: padding,
                  height: headerHeight,
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: groupColor.withValues(
                            alpha: section.isActive ? 0.42 : 0.22,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: groupColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                headerLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color:
                                          ContextualTreemapPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(section.averageScore * 100).round()}%',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: ContextualTreemapPalette.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
                for (final tile in section.tiles)
                  _AnimatedRect(
                    rect: _rectWithin(
                      _rectFromNormalized(
                        tile.rect01,
                        innerRect.width,
                        innerRect.height,
                      ),
                      innerRect,
                    ),
                    child: _ContextTaskTile(
                      layout: tile,
                      group: section.group,
                      isActiveSection: section.isActive,
                      isSelected:
                          selectedTaskId == tile.seed.rankedTask.task.id,
                      onTap: () => onTaskSelected(tile.seed.rankedTask),
                      colorScheme: colorScheme,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContextTaskTile extends StatelessWidget {
  const _ContextTaskTile({
    required this.layout,
    required this.group,
    required this.isActiveSection,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final ContextTreemapTileLayout layout;
  final ContextTreemapGroup group;
  final bool isActiveSection;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final tier = _tierFor(size);
        final rankedTask = layout.seed.rankedTask;
        final fillColor = ContextualTreemapPalette.tileColor(
          rankedTask: rankedTask,
          group: group,
          colorScheme: colorScheme,
          isActiveSection: isActiveSection,
          isSelected: isSelected,
        );
        final borderColor = ContextualTreemapPalette.tileBorderColor(
          rankedTask: rankedTask,
          group: group,
          colorScheme: colorScheme,
          isSelected: isSelected,
        );
        final textColor = ContextualTreemapPalette.textColorFor(fillColor);
        final mutedTextColor =
            ContextualTreemapPalette.mutedTextColorFor(fillColor);
        final title = rankedTask.task.title;
        final minutes = '${rankedTask.task.minutes} min';
        final relevance = '${(rankedTask.score * 100).round()}% match';
        final isEs = Localizations.localeOf(context).languageCode == 'es';
        final stateLabel = rankedTask.task.isBlocked
            ? (isEs ? ', bloqueada' : ', blocked')
            : '';
        final semanticLabel = isEs
            ? 'Tarea ${rankedTask.task.title}, ${(rankedTask.score * 100).round()} por ciento de afinidad contextual, ${rankedTask.task.minutes} minutos$stateLabel'
            : 'Task ${rankedTask.task.title}, ${(rankedTask.score * 100).round()} percent contextual match, ${rankedTask.task.minutes} minutes$stateLabel';

        return Semantics(
          button: true,
          label: semanticLabel,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(EisenRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.all(tier.padding),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(EisenRadius.md),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: fillColor.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  children: [
                    if (rankedTask.task.isBlocked &&
                        tier.level != _TileTierLevel.micro)
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          Icons.lock_clock_outlined,
                          size: math.min(18, tier.metaSize + 2),
                          color: ContextualTreemapPalette.alertStrong,
                        ),
                      ),
                    Positioned.fill(
                      child: _buildTileContent(
                        context,
                        tier: tier,
                        title: title,
                        minutes: minutes,
                        relevance: relevance,
                        textColor: textColor,
                        mutedTextColor: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileContent(
    BuildContext context, {
    required _TileTier tier,
    required String title,
    required String minutes,
    required String relevance,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    switch (tier.level) {
      case _TileTierLevel.large:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: tier.titleSize,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              relevance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: tier.metaSize,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              minutes,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: tier.metaSize + 0.3,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      case _TileTierLevel.medium:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: tier.titleSize,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
              ),
            ),
            Text(
              minutes,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: tier.metaSize,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        );
      case _TileTierLevel.small:
        return Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: tier.titleSize,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      case _TileTierLevel.tiny:
        final initials = _initials(title);
        return Center(
          child: Text(
            initials,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: tier.titleSize,
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
        );
      case _TileTierLevel.micro:
        return const SizedBox.expand();
    }
  }

  String _initials(String title) {
    final parts = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return '';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  _TileTier _tierFor(Size size) {
    final shortest = math.min(size.width, size.height);
    final area = size.width * size.height;
    if (shortest < 30 || area < 900) {
      return const _TileTier(
        level: _TileTierLevel.micro,
        titleSize: 0,
        metaSize: 0,
        padding: 2,
      );
    }
    if (shortest >= 118 && area >= 15000) {
      return _TileTier(
        level: _TileTierLevel.large,
        titleSize: (shortest * 0.18).clamp(18.0, 24.0),
        metaSize: (shortest * 0.10).clamp(12.0, 14.0),
        padding: 12,
      );
    }
    if (shortest >= 78 && area >= 6200) {
      return _TileTier(
        level: _TileTierLevel.medium,
        titleSize: (shortest * 0.16).clamp(14.0, 18.0),
        metaSize: (shortest * 0.09).clamp(10.0, 12.0),
        padding: 10,
      );
    }
    if (shortest >= 48 && area >= 2400) {
      return _TileTier(
        level: _TileTierLevel.small,
        titleSize: (shortest * 0.18).clamp(11.0, 13.0),
        metaSize: 10,
        padding: 8,
      );
    }
    return _TileTier(
      level: _TileTierLevel.tiny,
      titleSize: (shortest * 0.24).clamp(10.0, 14.0),
      metaSize: 9,
      padding: 4,
    );
  }
}

class _AnimatedRect extends StatelessWidget {
  const _AnimatedRect({
    required this.rect,
    required this.child,
  });

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }
}

class _TileTier {
  const _TileTier({
    required this.level,
    required this.titleSize,
    required this.metaSize,
    required this.padding,
  });

  final _TileTierLevel level;
  final double titleSize;
  final double metaSize;
  final double padding;
}

enum _TileTierLevel { large, medium, small, tiny, micro }

Rect _rectFromNormalized(Rect normalized, double width, double height) {
  return Rect.fromLTWH(
    normalized.left * width,
    normalized.top * height,
    normalized.width * width,
    normalized.height * height,
  );
}

Rect _rectWithin(Rect childRect, Rect parentRect) {
  return Rect.fromLTWH(
    parentRect.left + childRect.left,
    parentRect.top + childRect.top,
    childRect.width,
    childRect.height,
  );
}

Rect _deflateRect(Rect rect, double amount) {
  return Rect.fromLTWH(
    rect.left + amount,
    rect.top + amount,
    math.max(0, rect.width - amount * 2),
    math.max(0, rect.height - amount * 2),
  );
}
