import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../domain/category_entity.dart';
import '../domain/category_repository.dart';

CategoryType _typeFromString(String value) {
  switch (value) {
    case 'income':
      return CategoryType.income;
    case 'both':
      return CategoryType.both;
    default:
      return CategoryType.expense;
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> _categories = MockData.categories
      .map(
        (c) => CategoryEntity(
          id: c['id'] as String,
          name: c['name'] as String,
          icon: c['icon'],
          color: c['color'],
          type: _typeFromString(c['type'] as String),
          inUse: c['inUse'] as bool,
        ),
      )
      .toList();

  void _assertNoDuplicateName(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    final duplicate = _categories.any(
      (c) => c.id != excludingId && c.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const AppFailure(
        'Ya existe una categoría con ese nombre.',
        code: 'duplicate_name',
      );
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_categories);
  }

  @override
  Future<CategoryEntity> createCategory(CategoryEntity category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _assertNoDuplicateName(category.name);
    final created = category.copyWith();
    _categories.add(created);
    return created;
  }

  @override
  Future<CategoryEntity> updateCategory(CategoryEntity category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) throw const AppFailure('Categoría no encontrada.');
    _assertNoDuplicateName(category.name, excludingId: category.id);
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final category = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => throw const AppFailure('Categoría no encontrada.'),
    );
    if (category.inUse) {
      throw const AppFailure(
        'Esta categoría está en uso y no puede eliminarse.',
        code: 'category_in_use',
      );
    }
    _categories.removeWhere((c) => c.id == id);
  }
}
