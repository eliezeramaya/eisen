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
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final trendsAsync = ref.watch(trendsProvider);

    final weekly = weeklyAsync.when<WeeklyStats?>(
        data: (v) => v, loading: () => null, error: (_, __) => null);
    final balance =
        balanceAsync.when<BalanceBreakdown?>(
            data: (v) => v, loading: () => null, error: (_, __) => null);
    final trends =
        trendsAsync.when<List<TrendPoint>?>(
            data: (v) => v, loading: () => null, error: (_, __) => null);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Center(child: AppLogoHomeButton()),
                const SizedBox(height: 8),
                Text(
                  'Estadísticas',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                WeeklySummarySection(weekly: weekly),
                const SizedBox(height: 16),
                EisenhowerBalanceSection(balance: balance),
                const SizedBox(height: 16),
                WeeklyFocusTrendSection(trend: trends),
                const SizedBox(height: 16),
                NudgesSection(weekly: weekly),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
