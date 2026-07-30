import 'score_entity.dart';

abstract class ScoreRepository {
  Future<ScoreEntity> getScore();
}
