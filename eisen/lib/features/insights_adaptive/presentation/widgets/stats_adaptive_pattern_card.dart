import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/insights_adaptive/domain/adaptive_providers.dart';
import 'package:eisen/features/insights_adaptive/domain/cluster_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsAdaptivePatternCard extends ConsumerWidget {
  const StatsAdaptivePatternCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(adaptivePolicyEngineProvider);
    return FutureBuilder(
      future: engine.getCurrentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EisenCard(
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final profile = snapshot.data;
        if (profile == null) return const SizedBox.shrink();
        final desc = _description(profile.cluster);
        final cta = _cta(profile.cluster, context);
        return EisenCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EisenSectionHeader(title: 'Patrón de productividad'),
              const SizedBox(height: 8),
              Text(
                'Tu patrón predominante esta semana',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (cta != null) cta,
            ],
          ),
        );
      },
    );
  }

  String _description(ProductivityCluster cluster) {
    return switch (cluster) {
      ProductivityCluster.nightSprinter =>
          'Tiendes a concentrar trabajo productivo en la noche. Cuida tu recuperación y define un cierre claro.',
      ProductivityCluster.morningStrong =>
          'Tus mañanas son fuertes y tus tardes más dispersas. Protege una franja temprana para Q2.',
      ProductivityCluster.starterButNotFinisher =>
          'Inicias muchas tareas pero completas pocas. Divide las grandes y reduce tu lista diaria.',
      ProductivityCluster.unknown =>
          'Aún no detectamos un patrón claro. Sigue usando Eisen y afinaremos tus recomendaciones.',
    };
  }

  Widget? _cta(ProductivityCluster cluster, BuildContext context) {
    switch (cluster) {
      case ProductivityCluster.morningStrong:
        return FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/focus'),
          icon: const Icon(Icons.wb_sunny_outlined),
          label: const Text('Planear bloque matutino'),
        );
      case ProductivityCluster.nightSprinter:
        return FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          icon: const Icon(Icons.nightlight_round),
          label: const Text('Configurar ritual de cierre'),
        );
      case ProductivityCluster.starterButNotFinisher:
        return FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/matrix'),
          icon: const Icon(Icons.call_split),
          label: const Text('Dividir tarea clave'),
        );
      case ProductivityCluster.unknown:
        return null;
    }
  }
}
