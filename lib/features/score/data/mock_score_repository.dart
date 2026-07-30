import '../../../mock/mock_data.dart';
import '../domain/score_entity.dart';
import '../domain/score_repository.dart';

class MockScoreRepository implements ScoreRepository {
  @override
  Future<ScoreEntity> getScore() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return ScoreEntity(
      score: MockData.financialScore,
      status: MockData.scoreStatus,
      positiveFactors: MockData.scorePositiveFactors,
      negativeFactors: MockData.scoreNegativeFactors,
      recommendations: MockData.scoreRecommendations,
      history: MockData.scoreHistory
          .map(
            (h) => ScoreHistoryPoint(
              month: h['month'] as DateTime,
              score: h['score'] as int,
            ),
          )
          .toList(),
    );
  }
}
