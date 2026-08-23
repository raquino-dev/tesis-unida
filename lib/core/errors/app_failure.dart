/// Representa un error de dominio. Los repositories (mock u HTTP en el
/// futuro) lanzan este tipo para que los ViewModels lo traten de forma
/// uniforme, sin acoplarse al origen del dato.
class AppFailure implements Exception {
  final String _message;
  final String? code;

  const AppFailure(this._message, {this.code});

  String get message => _safeUserMessage(_normalizeSpanishText(_message));

  @override
  String toString() => message;
}

/// Convierte errores técnicos en texto seguro para mostrar en la interfaz.
/// También compone las tildes que puedan llegar separadas desde un servicio.
String appErrorMessage(
  Object error, {
  String fallback = 'Ocurrió un error inesperado. Intentá nuevamente.',
}) {
  final raw = switch (error) {
    // Conservamos el texto original dentro de esta librería para poder
    // reemplazar un detalle técnico por el fallback específico del flujo.
    AppFailure failure => failure._message,
    FormatException format => format.message.toString(),
    _ => fallback,
  };
  return _safeUserMessage(
    _normalizeSpanishText(raw.trim().isEmpty ? fallback : raw.trim()),
    fallback: fallback,
  );
}

/// Evita exponer mensajes internos del servidor o de la base de datos en la
/// interfaz. Las validaciones de negocio ya llegan en español y se conservan;
/// los detalles técnicos conocidos se reemplazan por una indicación accionable.
String _safeUserMessage(
  String value, {
  String fallback = 'Ocurrió un error inesperado. Intentá nuevamente.',
}) {
  final normalized = value.trim();
  final lower = normalized.toLowerCase();
  const technicalFragments = <String>[
    'an error occurred while saving the entity changes',
    'see the inner exception for details',
    'dbupdateexception',
    'postgresexception',
    'permission denied for schema',
    'failed executing dbcommand',
    'stack trace',
  ];
  if (technicalFragments.any(lower.contains)) return fallback;
  return normalized;
}

String _normalizeSpanishText(String value) {
  const replacements = <String, String>{
    'Ã¡': 'á',
    'Ã©': 'é',
    'Ã­': 'í',
    'Ã³': 'ó',
    'Ãº': 'ú',
    'Ã': 'Á',
    'Ã‰': 'É',
    'Ã': 'Í',
    'Ã“': 'Ó',
    'Ãš': 'Ú',
    'Ã±': 'ñ',
    'Ã‘': 'Ñ',
    'Ã¼': 'ü',
    'Ãœ': 'Ü',
    'Â¿': '¿',
    'Â¡': '¡',
    'Â': '',
    'a\u0301': 'á',
    'e\u0301': 'é',
    'i\u0301': 'í',
    'o\u0301': 'ó',
    'u\u0301': 'ú',
    'A\u0301': 'Á',
    'E\u0301': 'É',
    'I\u0301': 'Í',
    'O\u0301': 'Ó',
    'U\u0301': 'Ú',
    'n\u0303': 'ñ',
    'N\u0303': 'Ñ',
    'u\u0308': 'ü',
    'U\u0308': 'Ü',
  };
  var normalized = value;
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized;
}
