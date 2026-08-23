import '../../../mock/mock_data.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';

class MockReportRepository implements ReportRepository {
  final CategoryRepository _categoryRepository;
  final MovementRepository _movementRepository;
  MockReportRepository(this._categoryRepository, this._movementRepository);

  @override
  Future<ReportEntity> getReport(
    ReportRange range, {
    DateTimeRange? customRange,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final categories = await _categoryRepository.getCategories();
    final allMovements = await _movementRepository.getMovements();
    final now = DateTime.now();
    final start = switch (range) {
      ReportRange.week => now.subtract(const Duration(days: 7)),
      ReportRange.month => DateTime(now.year, now.month, 1),
      ReportRange.quarter => now.subtract(const Duration(days: 90)),
      ReportRange.year => DateTime(now.year, 1, 1),
      ReportRange.custom =>
        customRange?.start ?? now.subtract(const Duration(days: 30)),
    };
    final end = range == ReportRange.custom ? (customRange?.end ?? now) : now;
    final movements = allMovements
        .where(
          (movement) =>
              !movement.date.isBefore(start) &&
              !movement.date.isAfter(end.add(const Duration(days: 1))),
        )
        .toList();
    final income = movements
        .where((movement) => movement.type == MovementType.income)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final expense = movements
        .where((movement) => movement.type == MovementType.expense)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    List<CategoryDistribution> distributionFor(
      MovementType type,
      double total,
    ) {
      final totals = <String, double>{};
      final movementCategories = <String, CategoryEntity>{};
      for (final movement in movements.where(
        (movement) => movement.type == type,
      )) {
        if (movement.categories.isEmpty) continue;
        final category = movement.categories.first;
        totals[category.id] = (totals[category.id] ?? 0) + movement.amount;
        movementCategories[category.id] = category;
      }
      return totals.entries.map((entry) {
        final category = categories
            .where((candidate) => candidate.id == entry.key)
            .firstOrNull;
        return CategoryDistribution(
          category: category ?? movementCategories[entry.key]!,
          amount: entry.value,
          percentage: total == 0 ? 0 : entry.value / total,
        );
      }).toList();
    }

    final expenseDistribution = distributionFor(MovementType.expense, expense);
    final incomeDistribution = distributionFor(MovementType.income, income);

    final trend = List.generate(6, (i) {
      final month = DateTime.now().subtract(Duration(days: 30 * (5 - i)));
      return MonthlyTrendPoint(
        month: month,
        income: MockData.monthlyIncome * (0.85 + i * 0.03),
        expense: MockData.monthlyExpense * (0.8 + i * 0.05),
      );
    });

    return ReportEntity(
      range: range,
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      distribution: expenseDistribution,
      incomeDistribution: incomeDistribution,
      trend: trend,
      insights: const [
        'Tu categoría con mayor gasto sigue siendo Alimentación.',
        'Tus ingresos crecieron de forma sostenida en los últimos meses.',
        'El gasto en Transporte es el que más varió respecto al período anterior.',
      ],
    );
  }
}
