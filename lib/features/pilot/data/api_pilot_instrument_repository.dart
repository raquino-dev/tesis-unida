import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';

class PilotInstrumentQuestion {
  const PilotInstrumentQuestion({
    required this.id,
    required this.order,
    required this.type,
    required this.text,
    required this.required,
    this.minimum,
    this.maximum,
  });

  final String id;
  final int order;
  final String type;
  final String text;
  final bool required;
  final int? minimum;
  final int? maximum;

  bool get isScale => type == 'escala';
}

class PilotInstrument {
  const PilotInstrument({
    required this.code,
    required this.version,
    required this.title,
    required this.description,
    required this.completed,
    required this.enabled,
    required this.questions,
    this.enabledFrom,
  });

  final String code;
  final String version;
  final String title;
  final String description;
  final bool completed;
  final bool enabled;
  final DateTime? enabledFrom;
  final List<PilotInstrumentQuestion> questions;

  factory PilotInstrument.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['preguntas'] as List<dynamic>? ?? const [];
    final enabledFromRaw = json['habilitadoDesde'] as String?;
    return PilotInstrument(
      code: json['codigo'] as String? ?? '',
      version: json['version'] as String? ?? '',
      title: json['titulo'] as String? ?? 'Encuesta del piloto',
      description: json['descripcion'] as String? ?? '',
      completed: json['respondido'] as bool? ?? false,
      enabled: json['habilitado'] as bool? ?? true,
      enabledFrom: enabledFromRaw == null ? null : DateTime.tryParse(enabledFromRaw),
      questions: rawQuestions
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PilotInstrumentQuestion(
              id: item['id'] as String,
              order: item['orden'] as int? ?? 0,
              type: item['tipo'] as String? ?? 'texto',
              text: item['texto'] as String? ?? '',
              required: item['requerida'] as bool? ?? false,
              minimum: item['minimo'] as int?,
              maximum: item['maximo'] as int?,
            ),
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}

class PilotInstrumentAnswer {
  const PilotInstrumentAnswer({
    required this.questionId,
    this.scaleValue,
    this.textValue,
  });

  final String questionId;
  final int? scaleValue;
  final String? textValue;

  Map<String, dynamic> toJson() => {
    'preguntaId': questionId,
    'valorEscala': scaleValue,
    'valorTexto': textValue,
  };
}

class ApiPilotInstrumentRepository {
  ApiPilotInstrumentRepository(this._api);

  final ApiClient _api;

  Future<PilotInstrument> get(String code) async => PilotInstrument.fromJson(
    (await _api.get('/instrumentos-piloto/$code')).object,
  );

  Future<void> submit(String code, List<PilotInstrumentAnswer> answers) async {
    await _api.post(
      '/instrumentos-piloto/$code/respuestas',
      body: {'respuestas': answers.map((answer) => answer.toJson()).toList()},
      offline: OfflineMutation(
        entityType: 'respuesta_instrumento',
        entityId: code,
        optimisticResponse: const <String, dynamic>{},
      ),
    );
  }
}
