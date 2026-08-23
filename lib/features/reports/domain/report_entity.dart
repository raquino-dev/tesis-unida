import '../../categories/domain/category_entity.dart';

enum ReportRange { week, month, quarter, year, custom }

class CategoryDistribution {
  final CategoryEntity category;
  final double amount;
  final double percentage;

  const CategoryDistribution({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class MonthlyTrendPoint {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class ReportEntity {
  final ReportRange range;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  /// Distribución de egresos. Se mantiene con este nombre por compatibilidad
  /// con el contrato original de reportes.
  final List<CategoryDistribution> distribution;
  final List<CategoryDistribution> incomeDistribution;
  final List<MonthlyTrendPoint> trend;
  final List<String> insights;

  const ReportEntity({
    required this.range,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.distribution,
    required this.incomeDistribution,
    required this.trend,
    required this.insights,
  });

  List<CategoryDistribution> get expenseDistribution => distribution;
}
