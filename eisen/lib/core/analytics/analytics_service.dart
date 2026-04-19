import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_event.dart';

/// Interfaz básica para registrar eventos de usuario.
abstract class AnalyticsService {
  Future<void> logEvent(UserEvent event);
  Future<List<UserEvent>> getEvents({
    DateTime? from,
    DateTime? to,
  });
  Future<void> clear();
}

/// Implementación local usando SharedPreferences como buffer persistente.
///
/// Decisión: se usa un buffer en JSON para evitar nuevas dependencias.
/// Se limita a [_maxEvents] entradas más recientes para evitar crecimiento
/// indefinido. Más adelante se puede migrar a Isar/SQLite sin cambiar la API.
class LocalAnalyticsService implements AnalyticsService {
  static const _key = 'analytics.events.v1';
  static const _maxEvents = 500;

  @override
  Future<void> logEvent(UserEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    List<dynamic> list;
    if (raw != null) {
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        list = [];
      }
    } else {
      list = [];
    }
    list.add(event.toJson());
    if (list.length > _maxEvents) {
      list = list.sublist(list.length - _maxEvents);
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  @override
  Future<List<UserEvent>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(UserEvent.fromJson)
          .toList();
      return list.where((e) {
        final after = from == null || !e.timestamp.isBefore(from);
        final before = to == null || e.timestamp.isBefore(to);
        return after && before;
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => LocalAnalyticsService(),
);
