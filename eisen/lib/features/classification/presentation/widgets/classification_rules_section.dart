import 'package:eisen/core/design_system/widgets/eisen_card.dart';
import 'package:eisen/core/design_system/widgets/eisen_section_header.dart';
import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/enums/energy_level.dart';
import 'package:eisen/features/classification/domain/enums/entry_kind.dart';
import 'package:eisen/features/classification/domain/enums/priority_level.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';
import 'package:eisen/features/classification/domain/enums/time_horizon.dart';
import 'package:eisen/features/classification/presentation/controllers/category_config_controller.dart';
import 'package:eisen/features/classification/presentation/controllers/classification_rules_controller.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:eisen/features/eisen_matrix/domain/quadrant_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationRulesSection extends ConsumerWidget {
  const ClassificationRulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(classificationRulesControllerProvider);
    final categories = ref.watch(categoryConfigControllerProvider);
    final controller = ref.read(classificationRulesControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EisenSectionHeader(
          title: 'Rules',
          subtitle:
              'Reglas explícitas con prioridad sobre aliases y heurísticas.',
        ),
        EisenCard(
          outlined: true,
          child: Column(
            children: [
              if (rules.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sin reglas guardadas todavía.'),
                ),
              for (final rule in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RuleTile(
                    rule: rule,
                    categories: categories,
                    onToggle: () => controller.toggleEnabled(rule.id),
                    onEdit: () => _openEditor(
                      context,
                      ref,
                      categories: categories,
                      initial: rule,
                    ),
                    onDelete: () => controller.remove(rule.id),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openEditor(
                    context,
                    ref,
                    categories: categories,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva regla'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required List<CategoryConfig> categories,
    ClassificationRule? initial,
  }) async {
    final result = await showModalBottomSheet<ClassificationRule>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RuleEditorSheet(
        categories: categories,
        initial: initial,
      ),
    );
    if (result == null) return;

    final controller = ref.read(classificationRulesControllerProvider.notifier);
    if (initial == null) {
      await controller.add(result);
    } else {
      await controller.update(result);
    }
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.categories,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassificationRule rule;
  final List<CategoryConfig> categories;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    CategoryConfig? targetCategory;
    for (final item in categories) {
      if (item.id == rule.targetCategoryId) {
        targetCategory = item;
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rule.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Switch(value: rule.isEnabled, onChanged: (_) => onToggle()),
            ],
          ),
          Text(
            rule.keywords.join(', '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(rule.matchType.label)),
              Chip(label: Text(rule.priority.label)),
              if (targetCategory != null)
                Chip(label: Text(targetCategory.name)),
              if (rule.targetKind != null)
                Chip(label: Text(rule.targetKind!.label)),
              if (rule.targetHorizon != null)
                Chip(label: Text(rule.targetHorizon!.label)),
              if (rule.targetEnergy != null)
                Chip(label: Text('Energía ${rule.targetEnergy!.label}')),
              if (rule.targetQuadrant != null)
                Chip(
                  label: Text(
                    getQuadrantLabel(
                      rule.targetQuadrant!,
                      QuadrantLabelStyle.professional,
                    ).title,
                  ),
                ),
              if (rule.targetTags.isNotEmpty)
                Chip(label: Text(rule.targetTags.join(', '))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleEditorSheet extends StatefulWidget {
  const _RuleEditorSheet({
    required this.categories,
    this.initial,
  });

  final List<CategoryConfig> categories;
  final ClassificationRule? initial;

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _keywordsController = TextEditingController(
    text: widget.initial?.keywords.join(', ') ?? '',
  );
  late final TextEditingController _tagsController = TextEditingController(
    text: widget.initial?.targetTags.join(', ') ?? '',
  );
  late String? _categoryId = widget.initial?.targetCategoryId;
  late EntryKind? _kind = widget.initial?.targetKind;
  late TimeHorizon? _horizon = widget.initial?.targetHorizon;
  late EnergyLevel? _energy = widget.initial?.targetEnergy;
  late PriorityLevel? _priorityLevel = widget.initial?.targetPriority;
  late Quadrant? _quadrant = widget.initial?.targetQuadrant;
  late RulePriority _rulePriority =
      widget.initial?.priority ?? RulePriority.normal;
  late RuleMatchType _matchType =
      widget.initial?.matchType ?? RuleMatchType.contains;
  late bool _enabled = widget.initial?.enabled ?? true;

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Nueva regla' : 'Editar regla',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords',
                  hintText: 'cliente, renders, entrega',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _categoryId,
                decoration:
                    const InputDecoration(labelText: 'Categoría destino'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  for (final category in widget.categories)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              _optionalEnumField<EntryKind>(
                label: 'Tipo opcional',
                value: _kind,
                values: EntryKind.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _kind = value),
              ),
              const SizedBox(height: 12),
              _optionalEnumField<TimeHorizon>(
                label: 'Horizonte opcional',
                value: _horizon,
                values: TimeHorizon.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _horizon = value),
              ),
              const SizedBox(height: 12),
              _optionalEnumField<EnergyLevel>(
                label: 'Energía opcional',
                value: _energy,
                values: EnergyLevel.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _energy = value),
              ),
              const SizedBox(height: 12),
              _optionalEnumField<PriorityLevel>(
                label: 'Prioridad inferida opcional',
                value: _priorityLevel,
                values: PriorityLevel.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _priorityLevel = value),
              ),
              const SizedBox(height: 12),
              _optionalEnumField<Quadrant>(
                label: 'Cuadrante sugerido opcional',
                value: _quadrant,
                values: Quadrant.values,
                labelFor: (item) => getQuadrantLabel(
                  item,
                  QuadrantLabelStyle.professional,
                ).title,
                onChanged: (value) => setState(() => _quadrant = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags opcionales',
                  hintText: 'cliente, render, pipeline',
                ),
              ),
              const SizedBox(height: 12),
              _requiredEnumField<RulePriority>(
                label: 'Prioridad de regla',
                value: _rulePriority,
                values: RulePriority.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _rulePriority = value),
              ),
              const SizedBox(height: 12),
              _requiredEnumField<RuleMatchType>(
                label: 'Match type',
                value: _matchType,
                values: RuleMatchType.values,
                labelFor: (item) => item.label,
                onChanged: (value) => setState(() => _matchType = value),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: const Text('Regla activa'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(
                  widget.initial == null ? 'Crear regla' : 'Guardar regla',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requiredEnumField<T extends Enum>({
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

  Widget _optionalEnumField<T extends Enum>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T value) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(
          // Generic optional enum item cannot be const with type params.
          value: null,
          child: Text('Sin definir'),
        ),
        for (final item in values)
          DropdownMenuItem<T?>(
            value: item,
            child: Text(labelFor(item)),
          ),
      ],
      onChanged: onChanged,
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final keywords = _keywordsController.text
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
    if (name.isEmpty || keywords.isEmpty) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    Navigator.of(context).pop(
      ClassificationRule(
        id: widget.initial?.id ?? 'rule-$stamp',
        name: name,
        keywords: keywords,
        matchType: _matchType,
        targetCategoryId: _categoryId,
        targetKind: _kind,
        targetHorizon: _horizon,
        targetEnergy: _energy,
        targetPriority: _priorityLevel,
        targetQuadrant: _quadrant,
        targetTags: _tagsController.text
            .split(',')
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toList(),
        priority: _rulePriority,
        enabled: _enabled,
        scoreBoost: widget.initial?.scoreBoost ?? 0.24,
        description: widget.initial?.description,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
