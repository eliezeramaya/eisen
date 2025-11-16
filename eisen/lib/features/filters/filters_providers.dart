import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active category filters selected by the user in the UI.
/// Defaults to empty (no filtering applied).
final activeCategoryFiltersProvider =
    NotifierProvider<ActiveCategoryFilters, List<String>>(
        ActiveCategoryFilters.new);

class ActiveCategoryFilters extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  /// Update the list of active filters
  void update(List<String> newFilters) {
    state = newFilters;
  }
}
