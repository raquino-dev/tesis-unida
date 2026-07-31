import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_category_repository.dart';
import '../data/api_category_repository.dart';
import '../domain/category_entity.dart';
import '../domain/category_repository.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiCategoryRepository(ref.watch(apiClientProvider));
  }
  return MockCategoryRepository();
});

class CategoryListViewModel
    extends StateNotifier<ViewState<List<CategoryEntity>>> {
  final CategoryRepository _repository;
  CategoryListViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final categories = await _repository.getCategories();
      state = categories.isEmpty
          ? const ViewState.empty()
          : ViewState.success(categories);
    } catch (e) {
      state = ViewState.error(e.toString());
    }
  }

  Future<String?> create(CategoryEntity category) async {
    try {
      await _repository.createCategory(category);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> update(CategoryEntity category) async {
    try {
      await _repository.updateCategory(category);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.deleteCategory(id);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }
}

final categoryListViewModelProvider =
    StateNotifierProvider<
      CategoryListViewModel,
      ViewState<List<CategoryEntity>>
    >((ref) {
      return CategoryListViewModel(ref.watch(categoryRepositoryProvider));
    });
