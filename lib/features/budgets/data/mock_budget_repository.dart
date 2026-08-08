import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';

BudgetPeriod _periodFromString(String value) {
  switch (value) {
    case 'weekly':
      return BudgetPeriod.weekly;
    case 'annual':
      return BudgetPeriod.annual;
    default:
      return BudgetPeriod.monthly;
  }
}

class MockBudgetRepository implements BudgetRepository {
  final CategoryRepository _categoryRepository;
  List<BudgetEntity>? _cache;
  int _sequence = 100;

  MockBudgetRepository(this._categoryRepository);

  Future<List<BudgetEntity>> _load() async {
    if (_cache != null) return _cache!;
    final categories = await _categoryRepository.getCategories();
    _cache = MockData.categoryBudgets.map((b) {
      final ids = List<String>.from(b['categoryIds'] as List);
      final budgetCategories = categories
          .where((c) => ids.contains(c.id))
          .toList();
      return BudgetEntity(
        id: b['id'] as String,
        name: b['name'] as String,
        amount: b['amount'] as double,
        spent: b['spent'] as double,
        period: _periodFromString(b['period'] as String),
        categories: budgetCategories,
      );
    }).toList();
    return _cache!;
  }

  void _assertNoDuplicateName(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    final duplicate = (_cache ?? []).any(
      (b) => b.id != excludingId && b.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const AppFailure(
        'Ya existe un presupuesto con ese nombre.',
        code: 'duplicate_name',
      );
    }
  }

  @override
  Future<BudgetEntity> getOverallBudget() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const BudgetEntity(
      id: 'overall',
      name: 'Presupuesto mensual',
      amount: MockData.budgetTotal,
      spent: MockData.budgetSpent,
    );
  }

  @override
  Future<List<BudgetEntity>> getCategoryBudgets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(await _load());
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final budgets = await _load();
    _assertNoDuplicateName(budget.name);
    final created = budget.copyWith();
    final withId = BudgetEntity(
      id: 'bud_${_sequence++}',
      name: created.name,
      amount: created.amount,
      spent: created.spent,
      period: created.period,
      categories: created.categories,
    );
    budgets.add(withId);
    return withId;
  }

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final budgets = await _load();
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index == -1) throw const AppFailure('Presupuesto no encontrado.');
    _assertNoDuplicateName(budget.name, excludingId: budget.id);
    budgets[index] = budget;
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final budgets = await _load();
    budgets.removeWhere((b) => b.id == id);
  }
}
