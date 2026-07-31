class ScoreHistoryPoint {
  final DateTime month;
  final int score;
  const ScoreHistoryPoint({required this.month, required this.score});
}

class ScoreEntity {
  final int score;
  final String status;
  final List<String> positiveFactors;
  final List<String> negativeFactors;
  final List<ScoreHistoryPoint> history;
  final List<String> recommendations;
  final String algorithmVersion;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ScoreEntity({
    required this.score,
    required this.status,
    required this.positiveFactors,
    required this.negativeFactors,
    required this.history,
    required this.recommendations,
    this.algorithmVersion = 'prototipo-local',
    required this.periodStart,
    required this.periodEnd,
  });
}
