import 'package:eisen/features/completed_tasks/domain/project_category.dart';
import 'package:eisen/ui/widgets/app_logo_home_button.dart';
import 'package:eisen/core/services/ui_prefs.dart';
import 'package:eisen/core/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stats_controller.dart';
import '../../data/stats_exporter.dart';
import '../../domain/models.dart';
import '../widgets/eisenhower_balance_section.dart';
import '../widgets/nudges_section.dart';
import '../widgets/stats_trends_section.dart';
import '../widgets/stats_productivity_scores_section.dart';
import '../widgets/weekly_focus_trend_section.dart';
import '../widgets/weekly_summary_section.dart';
import 'package:eisen/features/insights_ml/presentation/widgets/stats_ml_section.dart';

/// StatsPage — UX/UI dashboard for motivation with calm visuals.
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final Debouncer _debounce = Debouncer(delay: const Duration(milliseconds: 200));

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final range = ref.watch(statsRangeProvider);
    final project = ref.watch(statsProjectProvider);
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final trendsAsync = ref.watch(trendsProvider);
    final uiPrefs = ref.watch(uiPrefsProvider);
    final advanced = uiPrefs.advancedInsightsEnabled;

    final weekly = weeklyAsync.when<WeeklyStats?>(
        data: (v) => v, loading: () => null, error: (_, __) => null);
    final balance = balanceAsync.when<BalanceBreakdown?>(
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
        actions: [
          IconButton(
            tooltip: 'Exportar',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showExportSheet(context, ref),
          ),
          const Padding(
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
                  alignment: isMobile ? Alignment.center : Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: StatsRange.values.map((r) {
                      final label = switch (r) {
                        StatsRange.last7Days => isEs ? '7 días' : '7 days',
                        StatsRange.last14Days => isEs ? '14 días' : '14 days',
                        StatsRange.last30Days => isEs ? '30 días' : '30 days',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: range == r,
                        onSelected: (value) {
                          if (!value) return;
                          _debounce.run(
                              () => ref.read(statsRangeProvider.notifier).set(r));
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: isMobile ? Alignment.center : Alignment.centerLeft,
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
                      _debounce.run(
                          () => ref.read(statsProjectProvider.notifier).set(value));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Nueva sección de tendencias avanzadas
                if (advanced) const StatsTrendsSection(),
                if (advanced) const SizedBox(height: 16),
                if (advanced) const StatsProductivityScoresSection(),
                if (advanced) const SizedBox(height: 16),
                if (advanced) const StatsMlSection(),
                const SizedBox(height: 16),
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

Future<void> _showExportSheet(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(statsRepoProvider);
  final range = ref.read(statsRangeProvider);
  final project = ref.read(statsProjectProvider);
  final bundle = await repo.exportReport(
      range: range, project: project, now: DateTime.now());

  if (!context.mounted) return;

  Future<void> handleExport(
      StatsExportFormat format, StatsExportDestination destination) async {
    Navigator.of(context).pop();
    final exporter = StatsExporter();
    try {
      final result =
          await exporter.export(bundle, format, destination: destination);
      if (!context.mounted) return;

      if (result.copiedToClipboard) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copiado al portapapeles'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (result.filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado en: ${result.filePath}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Archivo guardado'),
                    content: SelectableText(result.filePath!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> handleExportAll() async {
    Navigator.of(context).pop();
    final exporter = StatsExporter();
    try {
      final results = await exporter.exportAll(bundle,
          destination: StatsExportDestination.documents);
      if (!context.mounted) return;

      final successful = results.values.where((r) => r.filePath != null).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successful archivos exportados'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Exportar estadísticas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON a Documentos'),
              subtitle: const Text('Datos estructurados'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => handleExport(
                  StatsExportFormat.json, StatsExportDestination.documents),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV a Documentos'),
              subtitle: const Text('Hoja de cálculo'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => handleExport(
                  StatsExportFormat.csv, StatsExportDestination.documents),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Texto a Documentos'),
              subtitle: const Text('Formato imprimible'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => handleExport(
                  StatsExportFormat.pdfLike, StatsExportDestination.documents),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar JSON'),
              subtitle: const Text('Al portapapeles'),
              onTap: () => handleExport(
                  StatsExportFormat.json, StatsExportDestination.clipboard),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar CSV'),
              subtitle: const Text('Al portapapeles'),
              onTap: () => handleExport(
                  StatsExportFormat.csv, StatsExportDestination.clipboard),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: handleExportAll,
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar todo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
