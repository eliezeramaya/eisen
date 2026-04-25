import 'package:eisen/features/classification/domain/entities/category_config.dart';
import 'package:eisen/features/classification/presentation/providers/classification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryConfigController extends Notifier<List<CategoryConfig>> {
  late final _repository = ref.read(classificationRepositoryProvider);

  @override
  List<CategoryConfig> build() {
    _load();
    return CategoryConfigDefaults.values;
  }

  Future<void> _load() async {
    state = await _repository.loadCategories();
  }

  Future<void> add(CategoryConfig category) async {
    state = [...state, category];
    await _repository.saveCategories(state);
  }

  Future<void> createCategory(CategoryConfig category) => add(category);

  Future<void> update(CategoryConfig category) async {
    state = [
      for (final item in state)
        if (item.id == category.id) category else item,
    ];
    await _repository.saveCategories(state);
  }

  Future<void> updateCategory(CategoryConfig category) => update(category);

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.saveCategories(state);
  }

  Future<void> deleteCategory(String id) => remove(id);

  Future<void> reorder(int oldIndex, int newIndex) async {
    final next = [...state]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    state = [
      for (var i = 0; i < next.length; i++) next[i].copyWith(sortOrder: i),
    ];
    await _repository.saveCategories(state);
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) {
    return reorder(oldIndex, newIndex);
  }

  Future<void> toggleEnabled(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isHidden: item.isEnabled) else item,
    ];
    await _repository.saveCategories(state);
  }

  Future<void> hideCategory(String id, {bool hidden = true}) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isHidden: hidden) else item,
    ];
    await _repository.saveCategories(state);
  }

  Future<void> resetDefaults() async {
    state = CategoryConfigDefaults.values;
    await _repository.saveCategories(state);
  }
}

final categoryConfigControllerProvider =
    NotifierProvider<CategoryConfigController, List<CategoryConfig>>(
  CategoryConfigController.new,
);
