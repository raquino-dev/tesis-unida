import 'category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<CategoryEntity> createCategory(CategoryEntity category);
  Future<CategoryEntity> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String id);
}
