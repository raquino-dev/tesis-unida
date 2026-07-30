import 'budget_entity.dart';

abstract class BudgetRepository {
  Future<BudgetEntity> getOverallBudget();
  Future<List<BudgetEntity>> getCategoryBudgets();
  Future<BudgetEntity> createBudget(BudgetEntity budget);
  Future<BudgetEntity> updateBudget(BudgetEntity budget);
  Future<void> deleteBudget(String id);
}
