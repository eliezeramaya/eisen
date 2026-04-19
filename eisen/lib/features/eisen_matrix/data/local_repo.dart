import 'package:eisen/core/services/storage_prefs.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';

abstract class MatrixRepository {
  Future<List<Task>> load();
  Future<void> save(List<Task> tasks);
}

class LocalPrefsMatrixRepository implements MatrixRepository {
  LocalPrefsMatrixRepository(this.storage);
  final StoragePrefs storage;

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
      categories: (j['categories'] as List?)?.cast<String>() ?? const [],
      notes: j['notes'] as String?,
      category: j['category'] as String?,
      locationTag: j['locationTag'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      radiusMeters: (j['radiusMeters'] as num?)?.toDouble(),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'] as String)
          : null,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'] as String)
          : null,
      completedAt: j['completedAt'] != null
          ? DateTime.tryParse(j['completedAt'] as String)
          : null,
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
        'categories': t.categories,
        'notes': t.notes,
        'category': t.category,
        'locationTag': t.locationTag,
        'latitude': t.latitude,
        'longitude': t.longitude,
        'radiusMeters': t.radiusMeters,
        'createdAt': t.createdAt?.toIso8601String(),
        'updatedAt': t.updatedAt?.toIso8601String(),
        'completedAt': t.completedAt?.toIso8601String(),
      };
}
