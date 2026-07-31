import '../../../core/network/api_client.dart';
import '../domain/alert_entity.dart';
import '../domain/alert_repository.dart';

class ApiAlertRepository implements AlertRepository {
  final ApiClient _api;
  final Map<String, int> _versions = {};

  ApiAlertRepository(this._api);

  @override
  Future<List<AlertEntity>> getAlerts() async {
    final page = (await _api.get('/alertas-financieras')).object;
    return (page['datos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AlertEntity> getAlertById(String id) async {
    final alert = _fromJson(
      (await _api.get('/alertas-financieras/$id')).object,
    );
    return alert.isRead ? alert : markAsRead(id);
  }

  @override
  Future<AlertEntity> markAsRead(String id) =>
      _update(id, {'leida': true, 'archivada': null});

  @override
  Future<void> archive(String id) async {
    await _update(id, {'leida': true, 'archivada': true});
  }

  Future<AlertEntity> _update(String id, Map<String, dynamic> body) async {
    if (!_versions.containsKey(id)) {
      _fromJson((await _api.get('/alertas-financieras/$id')).object);
    }
    return _fromJson(
      (await _api.patch(
        '/alertas-financieras/$id',
        body: body,
        headers: {'If-Match': '"${_versions[id]}"'},
      )).object,
    );
  }

  AlertEntity _fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    _versions[id] = version;
    return AlertEntity(
      id: id,
      title: json['titulo'] as String,
      message: json['mensaje'] as String,
      level: switch (json['nivel']) {
        'critica' => AlertLevel.error,
        'advertencia' => AlertLevel.warning,
        _ => AlertLevel.info,
      },
      date: DateTime.parse(json['fecha'] as String).toLocal(),
      whatHappened: json['queOcurrio'] as String,
      dataUsed: json['datosUtilizados'] as String,
      impact: json['impacto'] as String,
      recommendation: json['recomendacion'] as String,
      isRead: json['leida'] as bool,
      version: version,
    );
  }
}
