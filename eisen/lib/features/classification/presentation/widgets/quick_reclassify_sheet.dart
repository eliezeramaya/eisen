import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_metadata.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';
import 'package:eisen/features/classification/domain/services/classification_correction_builder.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';

class QuickReclassifyResult {
  const QuickReclassifyResult({
    required this.metadata,
    required this.rememberDecision,
    required this.createRule,
  });

  final ClassificationMetadata metadata;
  final bool rememberDecision;
  final bool createRule;
}

class QuickReclassifySheet extends StatefulWidget {
  const QuickReclassifySheet({
    super.key,
    required this.metadata,
    required this.categories,
  });

  final ClassificationMetadata metadata;
  final List<CategoryConfig> categories;

  @override
  State<QuickReclassifySheet> createState() => _QuickReclassifySheetState();
}

class _QuickReclassifySheetState extends State<QuickReclassifySheet> {
  late String? _categoryId = widget.metadata.categoryId;
  late EntryKind _entryKind = widget.metadata.entryKind;
  late Quadrant? _suggestedQuadrant = widget.metadata.suggestedQuadrant;
  late bool _rememberDecision = false;
  late bool _createRule = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reclasificar rápido',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajusta lo mínimo necesario y sigue. Si quieres, también puedes recordar esta decisión para próximas capturas.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              _enumField<EntryKind>(
                label: 'Tipo',
                value: _entryKind,
                values: EntryKind.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _entryKind = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Quadrant?>(
                initialValue: _suggestedQuadrant,
                decoration: const InputDecoration(
                  labelText: 'Cuadrante sugerido',
                ),
                items: [
                  const DropdownMenuItem<Quadrant?>(
                    value: null,
                    child: Text('Sin sugerencia'),
                  ),
                  for (final quadrant in Quadrant.values)
                    DropdownMenuItem<Quadrant?>(
                      value: quadrant,
                      child: Text(
                        getQuadrantLabel(
                          quadrant,
                          QuadrantLabelStyle.professional,
                        ).title,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _suggestedQuadrant = value),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _rememberDecision,
                onChanged: (value) => setState(() => _rememberDecision = value),
                title: const Text('Recordar esta decisión'),
                subtitle: const Text(
                  'La app podrá aprender de esta corrección.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _createRule,
                onChanged: (value) => setState(() => _createRule = value),
                title: const Text('Crear regla con esta corrección'),
                subtitle: const Text(
                  'Genera una regla simple basada en el término detectado.',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: const Text('Guardar corrección'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enumField<T extends Enum>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(
            value: item,
            child: Text(labelFor(item)),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  void _save() {
    Navigator.of(context).pop(
      QuickReclassifyResult(
        metadata: buildUserCorrectedMetadata(
          widget.metadata.copyWith(
            categoryId: _categoryId,
            entryKind: _entryKind,
            suggestedQuadrant: _suggestedQuadrant,
            clearSuggestedQuadrant: _suggestedQuadrant == null,
          ),
        ),
        rememberDecision: _rememberDecision,
        createRule: _createRule,
      ),
    );
  }
}

ClassificationRule buildRuleFromReclassification({
  required String inputText,
  required ClassificationMetadata corrected,
}) {
  final keyword = _extractLearnableToken(
        corrected.matchedKeywords.isEmpty
            ? inputText
            : corrected.matchedKeywords.first,
      ) ??
      'entrada';
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return ClassificationRule(
    id: 'rule-$stamp',
    name: 'Regla para "$keyword"',
    keywords: <String>[keyword],
    matchType: RuleMatchType.contains,
    targetCategoryId: corrected.categoryId,
    targetKind: corrected.entryKind,
    targetHorizon: corrected.timeHorizon,
    targetEnergy: corrected.energyLevel,
    targetPriority: corrected.priorityLevel,
    targetQuadrant: corrected.suggestedQuadrant,
    targetTags: <String>[keyword],
    priority: RulePriority.high,
    scoreBoost: 0.24,
    description: 'Creada desde una corrección rápida.',
    isUserCreated: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

String? _extractLearnableToken(String input) {
  final tokens = input
      .toLowerCase()
      .split(RegExp(r'[^a-zA-Záéíóúñ0-9]+'))
      .where((item) => item.length >= 4)
      .where(
        (item) => !const {
          'para',
          'quiero',
          'empezar',
          'terminar',
          'esta',
          'semana',
        }.contains(item),
      )
      .toList();
  if (tokens.isEmpty) return null;
  return tokens.first;
}
