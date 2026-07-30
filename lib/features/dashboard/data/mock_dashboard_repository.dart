import '../../../mock/mock_data.dart';
import '../../categories/domain/category_repository.dart';
import '../../recurring_movements/domain/recurring_movement_entity.dart';
import '../../recurring_movements/domain/recurring_movement_repository.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary_entity.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  final CategoryRepository _categoryRepository;
  final RecurringMovementRepository _recurringMovementRepository;
  final MovementRepository _movementRepository;
  MockDashboardRepository(
    this._categoryRepository,
    this._recurringMovementRepository,
    this._movementRepository,
  );

  @override
  Future<DashboardSummaryEntity> getSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final categories = await _categoryRepository.getCategories();
    final movements = await _movementRepository.getMovements();
    final now = DateTime.now();
    final monthMovements = movements
        .where(
          (movement) =>
              movement.date.year == now.year &&
              movement.date.month == now.month,
        )
        .toList();
    final totalIncome = monthMovements
        .where((movement) => movement.type == MovementType.income)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalExpense = monthMovements
        .where((movement) => movement.type == MovementType.expense)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final categoryTotals = <String, double>{};
    for (final movement in monthMovements.where(
      (movement) => movement.type == MovementType.expense,
    )) {
      for (final category in movement.categories) {
        categoryTotals[category.id] =
            (categoryTotals[category.id] ?? 0) + movement.amount;
      }
    }
    final rankedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = rankedCategories.take(3).map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      final spent = entry.value;
      return TopCategorySpend(
        category: category,
        amount: spent,
        percentage: totalExpense == 0
            ? 0
            : (spent / totalExpense).clamp(0, 1).toDouble(),
      );
    }).toList();

    final recurring = await _recurringMovementRepository
        .getRecurringMovements();
    final upcoming = recurring
        .where((r) => r.status == RecurringStatus.active)
        .take(3)
        .map(
          (r) => UpcomingRecurringItem(
            name: r.description,
            amount: r.amount,
            date: r.nextExecutionDate,
          ),
        )
        .toList();

    final alertHighlights = MockData.alerts
        .take(2)
        .map((a) => a['message'] as String)
        .toList();

    return DashboardSummaryEntity(
      userName: MockData.userName,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      budgetTotal: MockData.budgetTotal,
      budgetAvailable: MockData.budgetTotal - totalExpense,
      financialScore: MockData.financialScore,
      topCategories: topCategories,
      upcomingRecurring: upcoming,
      alertHighlights: alertHighlights,
    );
  }
}
