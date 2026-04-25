import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassificationRulesController extends Notifier<List<ClassificationRule>> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  List<ClassificationRule> build() {
    _load();
    return const <ClassificationRule>[];
  }

  Future<void> _load() async {
    state = await _repository.loadRules();
  }

  Future<void> add(ClassificationRule rule) async {
    final now = DateTime.now();
    state = [
      ...state,
      rule.copyWith(
        isUserCreated: true,
        createdAt: rule.createdAt ?? now,
        updatedAt: now,
      ),
    ];
    await _repository.saveRules(state);
  }

  Future<void> createRule(ClassificationRule rule) => add(rule);

  Future<void> update(ClassificationRule rule) async {
    state = [
      for (final item in state)
        if (item.id == rule.id) rule else item,
    ];
    await _repository.saveRules(state);
  }

  Future<void> updateRule(ClassificationRule rule) => update(rule);

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.saveRules(state);
  }

  Future<void> deleteRule(String id) => remove(id);

  Future<void> toggleEnabled(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(enabled: !item.enabled) else item,
    ];
    await _repository.saveRules(state);
  }

  Future<void> enableRule(String id) => _setEnabled(id, true);

  Future<void> disableRule(String id) => _setEnabled(id, false);

  Future<void> _setEnabled(String id, bool enabled) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(enabled: enabled) else item,
    ];
    await _repository.saveRules(state);
  }
}

final classificationRulesControllerProvider =
    NotifierProvider<ClassificationRulesController, List<ClassificationRule>>(
  ClassificationRulesController.new,
);
