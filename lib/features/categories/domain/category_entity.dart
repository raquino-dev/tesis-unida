import 'package:flutter/material.dart';

/// Tipo de movimiento al que aplica la categoría. `both` permite usarla
/// tanto en gastos como en ingresos (p. ej. "Otros").
enum CategoryType { expense, income, both }

extension CategoryTypeLabel on CategoryType {
  String get label {
    switch (this) {
      case CategoryType.expense:
        return 'Gasto';
      case CategoryType.income:
        return 'Ingreso';
      case CategoryType.both:
        return 'Ambos';
    }
  }

  bool appliesTo(CategoryType movementType) =>
      this == CategoryType.both || this == movementType;
}

class CategoryEntity {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;
  final bool inUse;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.both,
    required this.inUse,
  });

  CategoryEntity copyWith({
    String? name,
    IconData? icon,
    Color? color,
    CategoryType? type,
    bool? inUse,
  }) {
    return CategoryEntity(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      inUse: inUse ?? this.inUse,
    );
  }
}
