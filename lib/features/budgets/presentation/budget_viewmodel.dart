import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../../categories/presentation/category_providers.dart';
import '../data/api_budget_repository.dart';
import '../data/mock_budget_repository.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => AppEnvironment.useApi
      ? ApiBudgetRepository(
          ref.watch(apiClientProvider),
          ref.watch(categoryRepositoryProvider),
        )
      : MockBudgetRepository(ref.watch(categoryRepositoryProvider)),
);

class BudgetOverview {
  final BudgetEntity overall;
  final List<BudgetEntity> categoryBudgets;
  const BudgetOverview({required this.overall, required this.categoryBudgets});
}

class BudgetViewModel extends StateNotifier<ViewState<BudgetOverview>> {
  final BudgetRepository _repository;
  BudgetViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final overall = await _repository.getOverallBudget();
      final categoryBudgets = await _repository.getCategoryBudgets();
      state = ViewState.success(
        BudgetOverview(overall: overall, categoryBudgets: categoryBudgets),
      );
    } catch (_) {
      state = const ViewState.error('No pudimos cargar tus presupuestos.');
    }
  }

  Future<String?> createBudget(BudgetEntity budget) async {
    try {
      await _repository.createBudget(budget);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> updateBudget(BudgetEntity budget) async {
    try {
      await _repository.updateBudget(budget);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<void> deleteBudget(String id) async {
    await _repository.deleteBudget(id);
    await load();
  }
}

final budgetViewModelProvider =
    StateNotifierProvider<BudgetViewModel, ViewState<BudgetOverview>>((ref) {
      return BudgetViewModel(ref.watch(budgetRepositoryProvider));
    });
