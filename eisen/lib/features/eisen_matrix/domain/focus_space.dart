import 'package:equatable/equatable.dart';

/// A saved focus space (matrix view by category/context).
///
/// Examples:
/// - General (no category filter)
/// - Trabajo
/// - Familia
/// - Proyecto 1
class FocusSpace extends Equatable {
  const FocusSpace({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.colorHex,
    required this.iconName,
    required this.isDefault,
  });

  /// Stable identifier for the space.
  final String id;

  /// Human-readable name: "General", "Trabajo", "Familia", etc.
  final String name;

  /// Category key associated with this space.
  ///
  /// For now this maps to [Task.category] (string). When null, the space
  /// represents the global matrix (no category filtering).
  final String? categoryId;

  /// Accent / background color encoded as hex, e.g. "#2196F3".
  final String colorHex;

  /// Icon name used by the UI, e.g. "work", "home", "school".
  ///
  /// Stored as a string to avoid tight coupling with Flutter's [IconData].
  final String iconName;

  /// Marks the default "General" space.
  ///
  /// - Exactly one space should have [isDefault] == true.
  /// - The default space cannot be deleted and should always have
  ///   [categoryId] == null.
  final bool isDefault;

  /// Built-in default space representing the full matrix (no category filter).
  static const FocusSpace general = FocusSpace(
    id: 'general',
    name: 'General',
    categoryId: null,
    colorHex: '#64748B', // Neutral accent
    iconName: 'grid_view',
    isDefault: true,
  );

  FocusSpace copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? colorHex,
    String? iconName,
    bool? isDefault,
  }) {
    return FocusSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        categoryId,
        colorHex,
        iconName,
        isDefault,
      ];
}
