import 'dart:convert';

import '../../../core/services/storage_prefs.dart';
import '../domain/entities.dart';

abstract class MatrixRepository {
  Future<List<Task>> load();
  Future<void> save(List<Task> tasks);
}

class LocalPrefsMatrixRepository implements MatrixRepository {
  final StoragePrefs storage;
  LocalPrefsMatrixRepository(this.storage);

  @override
  Future<List<Task>> load() async {
    final map = await storage.loadJson();
    final list = (map['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return list.map(_fromJson).toList();
  }

  @override
  Future<void> save(List<Task> tasks) async {
    final data = {
      'tasks': tasks.map(_toJson).toList(),
    };
    await storage.saveJson(data);
  }

  static Task _fromJson(Map<String, dynamic> j) {
    return Task(
      id: j['id'] as String,
      title: j['title'] as String,
      quadrant: Quadrant.values[j['quadrant'] as int],
      priority: j['priority'] as int,
      minutes: j['minutes'] as int,
      due: j['due'] != null ? DateTime.tryParse(j['due'] as String) : null,
      tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      notes: j['notes'] as String?,
      category: j['category'] as String?,
    );
  }

  static Map<String, Object?> _toJson(Task t) => {
        'id': t.id,
        'title': t.title,
        'quadrant': t.quadrant.index,
        'priority': t.priority,
        'minutes': t.minutes,
        'due': t.due?.toIso8601String(),
        'tags': t.tags,
        'notes': t.notes,
        'category': t.category,
      };
}
