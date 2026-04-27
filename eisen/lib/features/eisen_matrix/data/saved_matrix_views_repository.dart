import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/matrix_view_filter.dart';
import '../domain/saved_matrix_view.dart';

/// Repository for saved matrix views (favorites).
abstract class SavedMatrixViewsRepository {
  Stream<List<SavedMatrixView>> watchSavedMatrixViews();
  Future<void> addSavedMatrixView(SavedMatrixView view);
  Future<void> deleteSavedMatrixView(String id);
}

/// Local implementation backed by [SharedPreferences].
class LocalSavedMatrixViewsRepository implements SavedMatrixViewsRepository {
  LocalSavedMatrixViewsRepository({SharedPreferences? prefs})
      : _prefsFuture = prefs != null
            ? Future.value(prefs)
            : SharedPreferences.getInstance();

  static const _storageKey = 'eisen.saved_matrix_views.v1';

  final Future<SharedPreferences> _prefsFuture;
  final StreamController<List<SavedMatrixView>> _controller =
      StreamController<List<SavedMatrixView>>.broadcast();

  bool _initialized = false;
  List<SavedMatrixView> _current = const [];

  @override
  Stream<List<SavedMatrixView>> watchSavedMatrixViews() {
    _ensureLoaded();
    return _controller.stream;
  }

  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await _prefsFuture;
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _current =
              decoded.whereType<Map<String, dynamic>>().map(_fromJson).toList();
        }
      } catch (_) {
        _current = const [];
      }
    }

    _emit();
  }

  Future<void> _save() async {
    final prefs = await _prefsFuture;
    final list = _current.map(_toJson).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<SavedMatrixView>.unmodifiable(_current));
    }
  }

  @override
  Future<void> addSavedMatrixView(SavedMatrixView view) async {
    await _ensureLoaded();
    // Replace if id already exists, otherwise append.
    final exists = _current.any((v) => v.id == view.id);
    if (exists) {
      _current = _current
          .map((v) => v.id == view.id ? view : v)
          .toList(growable: false);
    } else {
      _current = [..._current, view];
    }
    _emit();
    await _save();
  }

  @override
  Future<void> deleteSavedMatrixView(String id) async {
    await _ensureLoaded();
    _current = _current.where((v) => v.id != id).toList(growable: false);
    _emit();
    await _save();
  }

  SavedMatrixView _fromJson(Map<String, dynamic> json) {
    return SavedMatrixView(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      focusSpaceId: json['focusSpaceId'] as String? ?? '',
      timeFilter: _timeFilterFromJson(json['timeFilter'] as String?),
      referenceDate:
          DateTime.tryParse(json['referenceDate'] as String? ?? '') ??
              DateTime.now(),
      onlyCompleted: json['onlyCompleted'] as bool? ?? false,
    );
  }

  Map<String, Object?> _toJson(SavedMatrixView view) => {
        'id': view.id,
        'name': view.name,
        'focusSpaceId': view.focusSpaceId,
        'timeFilter': view.timeFilter.name,
        'referenceDate': view.referenceDate.toIso8601String(),
        'onlyCompleted': view.onlyCompleted,
      };

  MatrixTimeFilterType _timeFilterFromJson(String? value) {
    if (value == null) return MatrixTimeFilterType.all;
    return MatrixTimeFilterType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MatrixTimeFilterType.all,
    );
  }
}

/// Riverpod provider exposing the saved matrix views repository.
final savedMatrixViewsRepositoryProvider = Provider<SavedMatrixViewsRepository>(
  (ref) => LocalSavedMatrixViewsRepository(),
);

/// Stream provider for saved matrix views (favorites).
final savedMatrixViewsStreamProvider = StreamProvider<List<SavedMatrixView>>(
  (ref) =>
      ref.watch(savedMatrixViewsRepositoryProvider).watchSavedMatrixViews(),
);
