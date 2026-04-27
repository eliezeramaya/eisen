import 'package:flutter/foundation.dart';

@immutable
class CategoryConfig {
  const CategoryConfig({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.description = '',
    this.keywords = const <String>[],
    this.aliases = const <String>[],
    this.parentCategoryId,
    this.isHidden = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.isSystem = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final String description;
  final List<String> keywords;
  final List<String> aliases;
  final String? parentCategoryId;
  final bool isHidden;
  final bool isArchived;
  final int sortOrder;
  final bool isSystem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get label => name;
  String get iconName => iconKey;
  bool get isEnabled => !isHidden;
  bool get isDefault => isSystem;
  bool get isVisibleInFilters => !isHidden;

  CategoryConfig copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    String? iconKey,
    List<String>? keywords,
    List<String>? aliases,
    String? parentCategoryId,
    bool? isHidden,
    bool? isArchived,
    int? sortOrder,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      aliases: aliases ?? this.aliases,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      isHidden: isHidden ?? this.isHidden,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CategoryConfigDefaults {
  const CategoryConfigDefaults._();

  static const values = <CategoryConfig>[
    CategoryConfig(
      id: 'inbox',
      name: 'Inbox',
      colorValue: 0xFF64748B,
      iconKey: 'inbox',
      description: 'Entradas temporales y tareas pendientes por clasificar.',
      keywords: <String>['inbox', 'captura', 'entrada'],
      aliases: <String>['sin clasificar', 'entrada'],
      isSystem: true,
      sortOrder: -1,
    ),
    CategoryConfig(
      id: 'work',
      name: 'Trabajo',
      colorValue: 0xFF275EFE,
      iconKey: 'work',
      description: 'Clientes, entregables y coordinación profesional.',
      keywords: <String>[
        'cliente',
        'renders',
        'brief',
        'entrega',
        'reunion',
        'proyecto',
      ],
      aliases: <String>['trabajo', 'cliente', 'oficina'],
      isSystem: true,
      sortOrder: 0,
    ),
    CategoryConfig(
      id: 'ideas',
      name: 'Ideas',
      colorValue: 0xFFFF8A00,
      iconKey: 'lightbulb',
      description: 'Conceptos, notas rápidas y exploración creativa.',
      keywords: <String>['idea', 'concepto', 'inspiracion', 'home'],
      aliases: <String>['ideas', 'creativo'],
      isSystem: true,
      sortOrder: 1,
    ),
    CategoryConfig(
      id: 'health',
      name: 'Salud',
      colorValue: 0xFF1F9D55,
      iconKey: 'favorite',
      description: 'Bienestar físico, mental y rutinas personales.',
      keywords: <String>['correr', 'ejercicio', 'salud', 'dormir'],
      aliases: <String>['salud', 'wellness'],
      isSystem: true,
      sortOrder: 2,
    ),
    CategoryConfig(
      id: 'finance',
      name: 'Finanzas',
      colorValue: 0xFF7C3AED,
      iconKey: 'payments',
      description: 'Pagos, cobros, presupuestos y compromisos financieros.',
      keywords: <String>['pagar', 'tarjeta', 'factura', 'presupuesto'],
      aliases: <String>['finanzas', 'dinero'],
      isSystem: true,
      sortOrder: 3,
    ),
    CategoryConfig(
      id: 'errands',
      name: 'Mandados',
      colorValue: 0xFFFB7185,
      iconKey: 'shopping_cart',
      description: 'Compras, pendientes cotidianos y logística personal.',
      keywords: <String>['comprar', 'leche', 'super', 'mandado'],
      aliases: <String>['compras', 'supermercado'],
      isSystem: true,
      sortOrder: 4,
    ),
    CategoryConfig(
      id: 'personal',
      name: 'Personal',
      colorValue: 0xFF0891B2,
      iconKey: 'person',
      description: 'Pendientes sin una categoría más específica.',
      keywords: <String>['llamar', 'casa', 'familia', 'personal'],
      aliases: <String>['personal', 'vida'],
      isSystem: true,
      sortOrder: 5,
    ),
  ];
}
