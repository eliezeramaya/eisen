import 'package:flutter/material.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stats_controller.dart';
import '../../domain/models.dart';
import '../widgets/card_balance.dart';
import '../widgets/card_focus.dart';
import '../widgets/card_nudges.dart';
import '../widgets/card_today.dart';
import '../widgets/card_trends.dart';
import '../widgets/card_week.dart';

/// StatsPage — UX/UI dashboard for motivation with calm visuals.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyStatsProvider);
    final streak = ref.watch(streakProvider);
    final balance = ref.watch(balanceProvider);
    final trends = ref.watch(trendsProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Row(
            children: [
              AppLogoHomeButton(),
              SizedBox(width: 8),
              Text('Estadísticas'),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            final weeklyVal = weekly.when<WeeklyStats?>(
                data: (v) => v, loading: () => null, error: (_, __) => null);
            final balanceVal = balance.when<BalanceBreakdown?>(
                data: (v) => v, loading: () => null, error: (_, __) => null);
            final trendsVal = trends.when<List<TrendPoint>?>(
                data: (v) => v, loading: () => null, error: (_, __) => null);
            final children = <Widget>[
              CardToday(weekly: weeklyVal, streak: streak),
              CardWeek(weekly: weeklyVal),
              CardBalance(balance: balanceVal),
              CardFocus(weekly: weeklyVal),
              CardTrends(trend: trendsVal),
              const CardNudges(),
            ];
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in children)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12), child: c),
                ],
              );
            }
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: children
                  .map((c) => SizedBox(
                      width: (constraints.maxWidth - 16) / 2, child: c))
                  .toList(),
            );
          }),
        ),
      ),
    );
  }
}
