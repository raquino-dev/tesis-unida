import 'prediction_entity.dart';

abstract class PredictionRepository {
  Future<PredictionEntity> getPrediction();
}
