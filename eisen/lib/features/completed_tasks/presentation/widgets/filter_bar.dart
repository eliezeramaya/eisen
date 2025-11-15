import 'package:flutter/material.dart';
import 'package:eisen/features/completed_tasks/domain/filters.dart';
import 'package:eisen/features/completed_tasks/domain/project_category.dart';

/// Filter bar for completed tasks.
///
/// Contains:
/// - Time filter segment (All/Year/Month/Week/Day)
/// - Date navigation (prev/next/today)
/// - Project filter dropdown
/// - Current filter description
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filter,
    required this.onTimeFilterChanged,
    required this.onDateChanged,
    required this.onProjectChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onResetToToday,
  });

  final CompletedTasksFilter filter;
  final ValueChanged<TimeFilterType> onTimeFilterChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<ProjectCategory?> onProjectChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final VoidCallback onResetToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time filter segments
          SegmentedButton<TimeFilterType>(
            segments: TimeFilterType.values.map((type) {
              return ButtonSegment(
                value: type,
                label: Text(type.displayName),
                icon: Icon(type.icon, size: 18),
              );
            }).toList(),
            selected: {filter.timeType},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onTimeFilterChanged(selection.first);
              }
            },
            showSelectedIcon: false,
          ),

          const SizedBox(height: 12),

          // Date navigation row (only show if not "all")
          if (filter.timeType != TimeFilterType.all)
            Row(
              children: [
                // Previous period
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPreviousPeriod,
                  tooltip: 'Período anterior',
                ),

                // Date picker button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showDatePicker(context, filter, onDateChanged),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _formatDateLabel(filter),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Today button
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: onResetToToday,
                  tooltip: 'Hoy',
                ),

                // Next period
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextPeriod,
                  tooltip: 'Período siguiente',
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Project filter dropdown
          DropdownButtonFormField<ProjectCategory>(
            value: filter.project ?? ProjectCategory.all,
            decoration: InputDecoration(
              labelText: 'Proyecto',
              prefixIcon: const Icon(Icons.category, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: ProjectCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value == ProjectCategory.all) {
                onProjectChanged(null);
              } else {
                onProjectChanged(value);
              }
            },
          ),

          const SizedBox(height: 8),

          // Current filter description
          Text(
            filter.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper functions outside the class
String _formatDateLabel(CompletedTasksFilter filter) {
  final date = filter.referenceDate;
  return switch (filter.timeType) {
    TimeFilterType.all => 'Todo',
    TimeFilterType.year => '${date.year}',
    TimeFilterType.month => '${_monthName(date.month)} ${date.year}',
    TimeFilterType.week => 'Semana del ${date.day}/${date.month}',
    TimeFilterType.day => '${date.day}/${date.month}/${date.year}',
  };
}

String _monthName(int month) => [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ][month - 1];

Future<void> _showDatePicker(
  BuildContext context,
  CompletedTasksFilter filter,
  ValueChanged<DateTime> onDateChanged,
) async {
  final date = filter.referenceDate;

  final picked = await showDatePicker(
    context: context,
    initialDate: date,
    firstDate: DateTime(2020, 1, 1),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    locale: const Locale('es'),
  );

  if (picked != null && picked != date) {
    onDateChanged(picked);
  }
}
