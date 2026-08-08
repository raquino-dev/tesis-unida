import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../domain/category_entity.dart';
import '../domain/category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  final ApiClient _api;
  final Map<String, int> _versions = {};

  ApiCategoryRepository(this._api);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final data = (await _api.get('/categorias')).object;
    return (data['elementos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryEntity> createCategory(CategoryEntity category) async =>
      _fromJson(
        (await _api.post('/categorias', body: _body(category))).object,
      );

  @override
  Future<CategoryEntity> updateCategory(CategoryEntity category) async {
    final version = await _versionFor(category.id);
    return _fromJson(
      (
        await _api.patch(
          '/categorias/${category.id}',
          body: _body(category),
          headers: {'If-Match': '"$version"'},
        )
      ).object,
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final version = await _versionFor(id);
    await _api.delete(
      '/categorias/$id',
      headers: {'If-Match': '"$version"'},
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    if (_versions[id] case final version?) return version;
    _fromJson((await _api.get('/categorias/$id')).object);
    return _versions[id]!;
  }

  Map<String, dynamic> _body(CategoryEntity category) => {
    'nombre': category.name,
    'tipo': switch (category.type) {
      CategoryType.income => 'ingreso',
      CategoryType.expense => 'gasto',
      CategoryType.both => 'ambos',
    },
    'icono': category.icon.codePoint.toRadixString(16),
    // La API y la columna `finanzas.categorias.color` usan el formato CSS
    // `#RRGGBB`; el canal alfa de Flutter no forma parte del contrato.
    'color':
        '#${(category.color.toARGB32() & 0x00ffffff).toRadixString(16).padLeft(6, '0')}',
  };

  CategoryEntity _fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    _versions[id] = (json['version'] as num).toInt();
    return CategoryEntity(
      id: id,
      name: json['nombre'] as String,
      icon: _icon(json['icono'] as String?),
      color: _color(json['color'] as String?),
      type: switch (json['tipo']) {
        'ingreso' => CategoryType.income,
        'gasto' => CategoryType.expense,
        _ => CategoryType.both,
      },
      inUse: json['enUso'] as bool? ?? false,
    );
  }

  IconData _icon(String? value) {
    if (value == Icons.restaurant_outlined.codePoint.toRadixString(16)) {
      return Icons.restaurant_outlined;
    }
    if (value == Icons.directions_bus_outlined.codePoint.toRadixString(16)) {
      return Icons.directions_bus_outlined;
    }
    if (value == Icons.home_outlined.codePoint.toRadixString(16)) {
      return Icons.home_outlined;
    }
    if (value == Icons.health_and_safety_outlined.codePoint.toRadixString(16)) {
      return Icons.health_and_safety_outlined;
    }
    if (value == Icons.payments_outlined.codePoint.toRadixString(16)) {
      return Icons.payments_outlined;
    }
    return Icons.category_outlined;
  }

  Color _color(String? value) {
    final normalized = (value ?? '').replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return Colors.blueGrey;
    return Color(normalized.length == 6 ? 0xff000000 | parsed : parsed);
  }
}
