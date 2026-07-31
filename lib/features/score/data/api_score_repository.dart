import '../../../core/network/api_client.dart';
import '../domain/score_entity.dart';
import '../domain/score_repository.dart';

class ApiScoreRepository implements ScoreRepository {
  final ApiClient _api;

  ApiScoreRepository(this._api);

  @override
  Future<ScoreEntity> getScore() async {
    final json = (await _api.get('/score-financiero')).object;
    final period = json['periodo'] as Map<String, dynamic>;
    return ScoreEntity(
      score: (json['score'] as num).toInt(),
      status: _status(json['estado'] as String),
      positiveFactors: (json['factoresPositivos'] as List<dynamic>? ?? const [])
          .cast<String>(),
      negativeFactors: (json['factoresNegativos'] as List<dynamic>? ?? const [])
          .cast<String>(),
      history: (json['historial'] as List<dynamic>? ?? const []).map((item) {
        final value = item as Map<String, dynamic>;
        return ScoreHistoryPoint(
          month: DateTime.parse('${value['periodo']}-01'),
          score: (value['score'] as num).toInt(),
        );
      }).toList(),
      recommendations: (json['recomendaciones'] as List<dynamic>? ?? const [])
          .cast<String>(),
      algorithmVersion: json['versionAlgoritmo'] as String,
      periodStart: DateTime.parse(period['desde'] as String),
      periodEnd: DateTime.parse(period['hasta'] as String),
    );
  }

  String _status(String value) => switch (value) {
    'en-observacion' => 'En observación',
    'critico' => 'Crítico',
    'saludable' => 'Saludable',
    'excelente' => 'Excelente',
    _ => value,
  };
}
