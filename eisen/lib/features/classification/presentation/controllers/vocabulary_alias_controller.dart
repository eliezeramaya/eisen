import 'package:eisen/features/classification/domain/entities/vocabulary_alias.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VocabularyAliasController extends Notifier<List<VocabularyAlias>> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  List<VocabularyAlias> build() {
    _load();
    return VocabularyAliasDefaults.values;
  }

  Future<void> _load() async {
    state = await _repository.loadAliases();
  }

  Future<void> add(VocabularyAlias alias) async {
    state = [...state, alias];
    await _repository.saveAliases(state);
  }

  Future<void> createAlias(VocabularyAlias alias) => add(alias);

  Future<void> update(VocabularyAlias alias) async {
    state = [
      for (final item in state)
        if (item.id == alias.id) alias else item,
    ];
    await _repository.saveAliases(state);
  }

  Future<void> updateAlias(VocabularyAlias alias) => update(alias);

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.saveAliases(state);
  }

  Future<void> deleteAlias(String id) => remove(id);

  Future<void> toggleEnabled(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(enabled: !item.enabled) else item,
    ];
    await _repository.saveAliases(state);
  }

  Future<void> toggleAlias(String id) => toggleEnabled(id);

  Future<void> resetDefaults() async {
    state = VocabularyAliasDefaults.values;
    await _repository.saveAliases(state);
  }
}

final vocabularyAliasControllerProvider =
    NotifierProvider<VocabularyAliasController, List<VocabularyAlias>>(
  VocabularyAliasController.new,
);
