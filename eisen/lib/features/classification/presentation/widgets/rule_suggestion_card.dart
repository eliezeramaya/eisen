import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:flutter/material.dart';

class RuleSuggestionCard extends StatelessWidget {
  const RuleSuggestionCard({
    super.key,
    required this.rule,
    required this.onApply,
    this.onDismiss,
  });

  final RuleSuggestion rule;
  final VoidCallback onApply;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return EisenCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(rule.description.isEmpty
              ? 'Sugerencia generada desde correcciones.'
              : rule.description),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(rule.matchType.label)),
              Chip(label: Text('patrón: ${rule.pattern}')),
              if (rule.categoryId != null)
                Chip(label: Text('categoría: ${rule.categoryId}')),
              Chip(label: Text('${(rule.confidence * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Descartar'),
                  ),
                FilledButton.tonalIcon(
                  onPressed: onApply,
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: const Text('Aplicar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
