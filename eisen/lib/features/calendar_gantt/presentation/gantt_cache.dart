import 'package:flutter/material.dart';

class _LruMap<K, V> {
  _LruMap({required this.capacity});
  final int capacity;
  final _map = <K, V>{};

  V? get(K key) {
    final v = _map.remove(key);
    if (v != null) _map[key] = v; // reinsert to mark as most-recent
    return v;
  }

  void set(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void clear() => _map.clear();
}

// Geometry cache key
class GeometryKey {
  const GeometryKey({
    required this.id,
    required this.viewStartMs,
    required this.startMs,
    required this.endMs,
    required this.pxPerDay,
    required this.lane,
  });
  final String id;
  final int viewStartMs;
  final int startMs;
  final int endMs;
  final double pxPerDay;
  final int lane;
  @override
  bool operator ==(Object other) =>
      other is GeometryKey &&
      other.id == id &&
      other.viewStartMs == viewStartMs &&
      other.startMs == startMs &&
      other.endMs == endMs &&
      (other.pxPerDay - pxPerDay).abs() < 1e-6 &&
      other.lane == lane;
  @override
  int get hashCode => Object.hash(
      id, viewStartMs, startMs, endMs, (pxPerDay * 1000).round(), lane);
}

// Text painter cache key
class TextKey {
  const TextKey(
      {required this.text,
      required this.fontSize,
      required this.maxWidth,
      required this.colorValue});
  final String text;
  final double fontSize;
  final double maxWidth;
  final int colorValue;
  @override
  bool operator ==(Object other) =>
      other is TextKey &&
      other.text == text &&
      (other.fontSize - fontSize).abs() < 1e-6 &&
      (other.maxWidth - maxWidth).abs() < 0.5 &&
      other.colorValue == colorValue;
  @override
  int get hashCode => Object.hash(
      text, (fontSize * 1000).round(), maxWidth.round(), colorValue);
}

class GanttCaches {
  static final geometry = _LruMap<GeometryKey, Rect>(capacity: 2048);
  static final text = _LruMap<TextKey, TextPainter>(capacity: 512);
}
