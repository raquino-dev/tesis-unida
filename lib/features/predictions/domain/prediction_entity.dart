class CategoryPrediction {
  final String categoryName;
  final double projectedAmount;
  final double variation;

  const CategoryPrediction({
    required this.categoryName,
    required this.projectedAmount,
    required this.variation,
  });
}

class PredictionHistoryPoint {
  final DateTime month;
  final double projected;
  final double actual;

  const PredictionHistoryPoint({
    required this.month,
    required this.projected,
    required this.actual,
  });
}

class PredictionEntity {
  final double projectedExpense;
  final double projectedBalance;
  final String topGrowthCategory;
  final String riskLevel;
  final List<CategoryPrediction> categoryPredictions;
  final List<PredictionHistoryPoint> history;
  final int historyMonths;
  final bool isPreliminary;
  final String modelVersion;
  final DateTime generatedAt;

  const PredictionEntity({
    required this.projectedExpense,
    required this.projectedBalance,
    required this.topGrowthCategory,
    required this.riskLevel,
    required this.categoryPredictions,
    required this.history,
    required this.historyMonths,
    required this.isPreliminary,
    this.modelVersion = 'prototipo-local',
    required this.generatedAt,
  });
}
