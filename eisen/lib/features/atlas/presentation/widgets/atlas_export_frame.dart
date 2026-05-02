import 'package:flutter/material.dart';

class AtlasExportFrame extends StatelessWidget {
  const AtlasExportFrame({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.date,
    this.groupingLabel,
    this.filtersLabel,
    this.visibleTaskCount,
    this.insights,
    this.footerLabel,
    this.includeHeader = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final DateTime? date;
  final String? groupingLabel;
  final String? filtersLabel;
  final int? visibleTaskCount;
  final List<String>? insights;
  final String? footerLabel;
  final bool includeHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ExportThemeSurface(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      child: includeHeader
          ? _ExportReportLayout(
              title: title ?? 'Atlas',
              subtitle: subtitle,
              date: date,
              groupingLabel: groupingLabel,
              filtersLabel: filtersLabel,
              visibleTaskCount: visibleTaskCount,
              insights: insights,
              footerLabel: footerLabel,
              child: child,
            )
          : child,
    );
  }
}

class _ExportThemeSurface extends StatelessWidget {
  const _ExportThemeSurface({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foregroundColor),
        child: IconTheme.merge(
          data: IconThemeData(color: foregroundColor),
          child: child,
        ),
      ),
    );
  }
}

class _ExportReportLayout extends StatelessWidget {
  const _ExportReportLayout({
    required this.title,
    required this.child,
    this.subtitle,
    this.date,
    this.groupingLabel,
    this.filtersLabel,
    this.visibleTaskCount,
    this.insights,
    this.footerLabel,
  });

  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? groupingLabel;
  final String? filtersLabel;
  final int? visibleTaskCount;
  final List<String>? insights;
  final String? footerLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExportHeader(
            title: title,
            subtitle: subtitle,
            date: date,
            groupingLabel: groupingLabel,
            filtersLabel: filtersLabel,
            visibleTaskCount: visibleTaskCount,
          ),
          if (insights != null && insights!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ExportInsights(insights: insights!),
          ],
          const SizedBox(height: 14),
          Expanded(child: child),
          if (footerLabel != null && footerLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ExportFooter(label: footerLabel!.trim()),
          ],
        ],
      ),
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader({
    required this.title,
    this.subtitle,
    this.date,
    this.groupingLabel,
    this.filtersLabel,
    this.visibleTaskCount,
  });

  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? groupingLabel;
  final String? filtersLabel;
  final int? visibleTaskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (date != null) _formatDate(date!),
      if (groupingLabel != null && groupingLabel!.trim().isNotEmpty)
        'Agrupación: ${groupingLabel!.trim()}',
      if (filtersLabel != null && filtersLabel!.trim().isNotEmpty)
        'Filtros: ${filtersLabel!.trim()}',
      if (visibleTaskCount != null) _taskCountLabel(visibleTaskCount!),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty)
                Text(
                  subtitle!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final item in meta)
                Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ExportInsights extends StatelessWidget {
  const _ExportInsights({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.56,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            for (final insight in insights)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      insight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportFooter extends StatelessWidget {
  const _ExportFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _taskCountLabel(int count) {
  if (count == 1) return '1 tarea visible';
  return '$count tareas visibles';
}
