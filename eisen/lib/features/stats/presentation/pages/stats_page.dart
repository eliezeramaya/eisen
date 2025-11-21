import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stats_controller.dart';
import '../../domain/models.dart';
import '../widgets/eisenhower_balance_section.dart';
import '../widgets/nudges_section.dart';
import '../widgets/weekly_focus_trend_section.dart';
import '../widgets/weekly_summary_section.dart';

/// StatsPage — UX/UI dashboard for motivation with calm visuals.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final range = ref.watch(statsRangeProvider);
    final project = ref.watch(statsProjectProvider);
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final trendsAsync = ref.watch(trendsProvider);

    final weekly = weeklyAsync.when<WeeklyStats?>(
        data: (v) => v, loading: () => null, error: (_, __) => null);
    final balance =
        balanceAsync.when<BalanceBreakdown?>(
            data: (v) => v, loading: () => null, error: (_, __) => null);
    final trends = trendsAsync.when<List<TrendPoint>?>(
        data: (v) => v, loading: () => null, error: (_, __) => null);
    final showBack = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        leading: showBack
            ? BackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLogoHomeButton(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            key: ValueKey(range),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment:
                      isMobile ? Alignment.center : Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: StatsRange.values.map((r) {
                      final label = switch (r) {
                        StatsRange.last7Days =>
                          isEs ? '7 días' : '7 days',
                        StatsRange.last14Days =>
                          isEs ? '14 días' : '14 days',
                        StatsRange.last30Days =>
                          isEs ? '30 días' : '30 days',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: range == r,
                        onSelected: (value) {
                          if (!value) return;
                          ref.read(statsRangeProvider.notifier).set(r);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment:
                      isMobile ? Alignment.center : Alignment.centerLeft,
                  child: DropdownButton<ProjectCategory>(
                    value: project,
                    underline: const SizedBox.shrink(),
                    items: ProjectCategory.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      ref
                          .read(statsProjectProvider.notifier)
                          .set(value);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                WeeklySummarySection(
                  weekly: weekly,
                  range: range,
                ),
                const SizedBox(height: 16),
                EisenhowerBalanceSection(balance: balance),
                const SizedBox(height: 16),
                WeeklyFocusTrendSection(
                  trend: trends,
                  range: range,
                ),
                const SizedBox(height: 16),
                const NudgesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
