import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_space.dart';

/// Repository for managing focus spaces (saved Eisenhower matrix contexts).
abstract class FocusSpaceRepository {
  Stream<List<FocusSpace>> watchFocusSpaces();
  Future<void> addFocusSpace(FocusSpace space);
  Future<void> updateFocusSpace(FocusSpace space);
  Future<void> deleteFocusSpace(String id);
}

/// Local implementation backed by [SharedPreferences].
///
/// Ensures that:
/// - There is always at least one focus space: [FocusSpace.general].
/// - The default "General" space:
///   - Has id "general"
///   - Has [categoryId] == null
///   - Cannot be deleted or renamed
class LocalFocusSpaceRepository implements FocusSpaceRepository {
  LocalFocusSpaceRepository({SharedPreferences? prefs})
      : _prefsFuture = prefs != null
            ? Future.value(prefs)
            : SharedPreferences.getInstance();

  static const _storageKey = 'eisen.focus_spaces.v1';

  final Future<SharedPreferences> _prefsFuture;
  final StreamController<List<FocusSpace>> _controller =
      StreamController<List<FocusSpace>>.broadcast();

  bool _initialized = false;
  List<FocusSpace> _current = const [FocusSpace.general];

  @override
  Stream<List<FocusSpace>> watchFocusSpaces() {
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
        // If anything goes wrong, fall back to default state.
        _current = const [FocusSpace.general];
      }
    }

    // Ensure a single default "General" space exists and is first.
    final hasGeneral = _current.any((s) => s.id == FocusSpace.general.id);
    final withoutGeneral =
        _current.where((s) => s.id != FocusSpace.general.id).toList();

    if (!hasGeneral) {
      _current = [FocusSpace.general, ...withoutGeneral];
    } else {
      // Normalize existing "general" entry to the canonical definition.
      final others = withoutGeneral;
      _current = [FocusSpace.general, ...others];
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
      _controller.add(List<FocusSpace>.unmodifiable(_current));
    }
  }

  @override
  Future<void> addFocusSpace(FocusSpace space) async {
    await _ensureLoaded();
    if (space.isDefault || space.id == FocusSpace.general.id) {
      // Prevent creating custom spaces masquerading as "General".
      return;
    }
    _current = [
      ..._current,
      space,
    ];
    _emit();
    await _save();
  }

  @override
  Future<void> updateFocusSpace(FocusSpace space) async {
    await _ensureLoaded();
    if (space.id == FocusSpace.general.id || space.isDefault) {
      // Keep "General" immutable in terms of identity and category filter.
      final updatedGeneral = FocusSpace.general.copyWith(
        colorHex: space.colorHex,
        iconName: space.iconName,
      );
      _current = [
        updatedGeneral,
        ..._current.where((s) => s.id != FocusSpace.general.id),
      ];
    } else {
      _current = _current
          .map((s) => s.id == space.id ? space.copyWith(isDefault: false) : s)
          .toList();
    }
    _emit();
    await _save();
  }

  @override
  Future<void> deleteFocusSpace(String id) async {
    await _ensureLoaded();
    if (id == FocusSpace.general.id) {
      // "General" cannot be deleted.
      return;
    }
    _current = _current.where((s) => s.id != id).toList();
    if (_current.isEmpty) {
      _current = const [FocusSpace.general];
    }
    _emit();
    await _save();
  }

  FocusSpace _fromJson(Map<String, dynamic> json) {
    return FocusSpace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      colorHex: json['colorHex'] as String? ?? '#64748B',
      iconName: json['iconName'] as String? ?? 'grid_view',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, Object?> _toJson(FocusSpace space) => {
        'id': space.id,
        'name': space.name,
        'categoryId': space.categoryId,
        'colorHex': space.colorHex,
        'iconName': space.iconName,
        'isDefault': space.isDefault,
      };
}

/// Riverpod provider exposing the focus space repository.
final focusSpaceRepositoryProvider = Provider<FocusSpaceRepository>(
  (ref) => LocalFocusSpaceRepository(),
);

/// Stream provider for the list of focus spaces.
final focusSpacesStreamProvider = StreamProvider<List<FocusSpace>>(
  (ref) => ref.watch(focusSpaceRepositoryProvider).watchFocusSpaces(),
);
