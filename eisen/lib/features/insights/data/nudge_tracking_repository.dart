import 'dart:convert';

import 'package:eisen/features/insights/domain/nudge_tracking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _trackingKey = 'nudges_tracking_data';

/// Repositorio para persistir datos de tracking de nudges.
///
/// Utiliza SharedPreferences para almacenar un mapa JSON con los datos
/// de tracking indexados por nudgeId.
class NudgeTrackingRepository {
  NudgeTrackingRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Obtiene todos los datos de tracking almacenados.
  Future<Map<String, NudgeTrackingData>> getAllTracking() async {
    final p = await prefs;
    final jsonString = p.getString(_trackingKey);
    if (jsonString == null) return {};

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return jsonMap.map(
        (key, value) => MapEntry(
          key,
          NudgeTrackingData.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      // Si hay error de parseo, retornar mapa vacío
      return {};
    }
  }

  /// Obtiene el tracking de un nudge específico.
  Future<NudgeTrackingData?> getTracking(String nudgeId) async {
    final all = await getAllTracking();
    return all[nudgeId];
  }

  /// Guarda o actualiza el tracking de un nudge.
  Future<void> saveTracking(NudgeTrackingData tracking) async {
    final all = await getAllTracking();
    all[tracking.nudgeId] = tracking;
    await _saveAll(all);
  }

  /// Guarda múltiples trackings a la vez.
  Future<void> saveMultiple(List<NudgeTrackingData> trackings) async {
    final all = await getAllTracking();
    for (final tracking in trackings) {
      all[tracking.nudgeId] = tracking;
    }
    await _saveAll(all);
  }

  /// Elimina el tracking de un nudge específico.
  Future<void> deleteTracking(String nudgeId) async {
    final all = await getAllTracking();
    all.remove(nudgeId);
    await _saveAll(all);
  }

  /// Elimina todos los trackings.
  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_trackingKey);
  }

  Future<void> _saveAll(Map<String, NudgeTrackingData> trackingMap) async {
    final jsonMap = trackingMap.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    final jsonString = jsonEncode(jsonMap);
    final p = await prefs;
    await p.setString(_trackingKey, jsonString);
  }
}

/// Provider del repositorio de tracking.
final nudgeTrackingRepositoryProvider = Provider<NudgeTrackingRepository>(
  (ref) => NudgeTrackingRepository(),
);
