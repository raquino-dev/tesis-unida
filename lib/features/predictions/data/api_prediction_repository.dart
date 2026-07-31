import '../../../core/network/api_client.dart';
import '../domain/prediction_entity.dart';
import '../domain/prediction_repository.dart';

class ApiPredictionRepository implements PredictionRepository {
  final ApiClient _api;

  ApiPredictionRepository(this._api);

  @override
  Future<PredictionEntity> getPrediction() async {
    final json = (await _api.get(
      '/proyecciones-gastos?ambito=privado&periodo=mensual',
    )).object;
    return PredictionEntity(
      projectedExpense: (json['gastoProyectado'] as num).toDouble(),
      projectedBalance: (json['balanceProyectado'] as num).toDouble(),
      topGrowthCategory: json['categoriaMayorCrecimiento'] as String,
      riskLevel: _capitalize(json['nivelRiesgo'] as String),
      categoryPredictions: (json['categorias'] as List<dynamic>? ?? const [])
          .map((item) {
            final value = item as Map<String, dynamic>;
            return CategoryPrediction(
              categoryName: value['nombre'] as String,
              projectedAmount: (value['montoProyectado'] as num).toDouble(),
              variation: (value['variacion'] as num).toDouble(),
            );
          })
          .toList(),
      history: (json['historial'] as List<dynamic>? ?? const []).map((item) {
        final value = item as Map<String, dynamic>;
        return PredictionHistoryPoint(
          month: DateTime.parse('${value['periodo']}-01'),
          projected: (value['proyectado'] as num).toDouble(),
          actual: (value['real'] as num).toDouble(),
        );
      }).toList(),
      historyMonths: (json['mesesHistorial'] as num).toInt(),
      isPreliminary: json['preliminar'] as bool,
      modelVersion: json['versionModelo'] as String,
      generatedAt: DateTime.parse(json['generadoEn'] as String).toLocal(),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
