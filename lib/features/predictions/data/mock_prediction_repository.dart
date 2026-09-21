import '../../../mock/mock_data.dart';
import '../domain/prediction_entity.dart';
import '../domain/prediction_repository.dart';
import '../../movements/domain/movement_repository.dart';

class MockPredictionRepository implements PredictionRepository {
  final MovementRepository movementRepository;
  MockPredictionRepository(this.movementRepository);

  @override
  Future<PredictionEntity> getPrediction() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final movements = await movementRepository.getMovements();
    final expenses = movements
        .where((movement) => movement.analyticalExpenseAmount != 0)
        .toList();
    final totalExpense = expenses.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalExpenseAmount,
    );
    final oldest = expenses.isEmpty
        ? DateTime.now()
        : expenses
              .map((movement) => movement.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final observedDays = DateTime.now().difference(oldest).inDays.clamp(1, 30);
    final projectedExpense = totalExpense / observedDays * 30;
    final byCategory = <String, double>{};
    for (final movement in expenses) {
      for (final category in movement.categories) {
        byCategory[category.name] =
            (byCategory[category.name] ?? 0) + movement.analyticalExpenseAmount;
      }
    }
    final ranked = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return PredictionEntity(
      projectedExpense: projectedExpense,
      projectedBalance: MockData.monthlyIncome - projectedExpense,
      topGrowthCategory: ranked.isEmpty ? 'Sin datos' : ranked.first.key,
      riskLevel: projectedExpense > MockData.monthlyIncome
          ? 'Alto'
          : projectedExpense > MockData.monthlyIncome * 0.8
          ? 'Medio'
          : 'Bajo',
      categoryPredictions: ranked
          .map(
            (entry) => CategoryPrediction(
              categoryName: entry.key,
              projectedAmount: entry.value / observedDays * 30,
              variation: 0.05 + ranked.indexOf(entry) * 0.03,
            ),
          )
          .toList(),
      history: MockData.predictionHistory
          .take(2)
          .map(
            (h) => PredictionHistoryPoint(
              month: h['month'] as DateTime,
              projected: h['projected'] as double,
              actual: h['actual'] as double,
            ),
          )
          .toList(),
      historyMonths: 1,
      isPreliminary: true,
      generatedAt: DateTime.now(),
    );
  }
}
