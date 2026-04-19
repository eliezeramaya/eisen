import 'package:eisen/features/focus/domain/focus_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FocusTopBar extends ConsumerWidget {
  const FocusTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(focusDashboardControllerProvider);
    final dateLabel =
        DateFormat('EEE d MMM').format(state.selectedDate).toUpperCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CircleIconButton(
                icon: Icons.home_outlined,
                onTap: () => context.go('/matrix'),
              ),
              const SizedBox(width: 10),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
              ),
              const Spacer(),
              _PeriodSelector(
                period: state.period,
                onSelected: (p) {
                  ref
                      .read(focusDashboardControllerProvider.notifier)
                      .setPeriod(p);
                },
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.timeline,
                onTap: () {
                  // TODO: Hook into focus history/settings once available.
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Divider(color: cs.outline.withValues(alpha: 0.12), height: 1),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          color: cs.surface,
        ),
        child: Icon(
          icon,
          size: 20,
          color: cs.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.onSelected,
  });

  final FocusPeriod period;
  final ValueChanged<FocusPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<FocusPeriod>(
      initialValue: period,
      offset: const Offset(0, 12),
      onSelected: onSelected,
      itemBuilder: (_) => FocusPeriod.values
          .map(
            (p) => PopupMenuItem<FocusPeriod>(
              value: p,
              child: Text(p.label),
            ),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            period == FocusPeriod.today ? 'TODAY' : period.label.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  letterSpacing: 1.2,
                ),
          ),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}
