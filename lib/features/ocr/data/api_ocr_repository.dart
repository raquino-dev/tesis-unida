import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../movements/domain/movement_entity.dart';
import '../domain/ocr_repository.dart';
import '../domain/ocr_result_entity.dart';

class ApiOcrRepository implements OcrRepository {
  final ApiClient _api;

  ApiOcrRepository(this._api);

  @override
  Future<OcrResultEntity> processReceipt(
    OcrSource source, {
    String? documentPath,
    String? documentName,
  }) async {
    if (documentPath == null || documentName == null) {
      throw const AppFailure('Seleccioná un comprobante válido.');
    }
    final bytes = await File(documentPath).readAsBytes();
    final metadata = _metadata(source, documentName);
    final response = await _api.multipart(
      '/documentos-financieros',
      fields: {'tipo': metadata.$1, 'ambito': 'privado'},
      fileField: 'archivo',
      fileBytes: bytes,
      fileName: documentName,
      mimeType: metadata.$2,
      headers: {
        'Idempotency-Key': _key('document'),
        'X-Content-SHA256': sha256.convert(bytes).toString(),
      },
    );
    final document = response.object;
    final processingId = document['procesamientoId'] as String;
    final process = await _waitForProcessing(processingId);
    return _fromProcess(
      process,
      source: source,
      documentId: document['id'] as String,
      documentPath: documentPath,
      documentName: documentName,
    );
  }

  @override
  Future<OcrResultEntity> correctReceipt(
    OcrResultEntity result, {
    required double amount,
    required DateTime date,
    required String merchant,
    required String categoryId,
  }) async {
    if (result.processingId == null) {
      return result.copyWith(
        amount: amount,
        date: date,
        merchant: merchant,
        suggestedCategoryId: categoryId,
        status: OcrStatus.success,
      );
    }
    final response = await _api.patch(
      '/procesamientos-documentales/${result.processingId}',
      headers: {'If-Match': '"${result.processingVersion}"'},
      body: {
        'datosDetectados': {
          'monto': amount.round(),
          'fecha': _date(date),
          'comercio': merchant,
          'categoriaSugeridaId': categoryId,
          'cdcSifen': result.source == OcrSource.xml
              ? result.documentReference
              : null,
        },
      },
    );
    return _fromProcess(
      response.object,
      source: result.source,
      documentId: result.documentId!,
      documentPath: result.documentPath,
      documentName: result.documentName,
    );
  }

  Future<Map<String, dynamic>> _waitForProcessing(String id) async {
    // El procesamiento pasa por el worker y puede tardar más que una llamada
    // HTTP convencional. Esperar hasta un minuto evita presentar un error
    // prematuro cuando el resultado ya está por llegar.
    for (var attempt = 0; attempt < 80; attempt++) {
      final json = (await _api.get('/procesamientos-documentales/$id')).object;
      final status = json['estado'] as String;
      if (status != 'pendiente' && status != 'procesando') return json;
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
    throw const AppFailure(
      'El comprobante continúa procesándose. Intentá nuevamente en unos segundos.',
      code: 'document_processing_timeout',
    );
  }

  OcrResultEntity _fromProcess(
    Map<String, dynamic> json, {
    required OcrSource source,
    required String documentId,
    required String? documentPath,
    required String? documentName,
  }) {
    final detected =
        json['datosDetectados'] as Map<String, dynamic>? ?? const {};
    final warnings = (json['advertencias'] as List<dynamic>? ?? const [])
        .cast<String>()
        .map(_warningForUser)
        .toList(growable: false);
    final rawDate = detected['fecha'] as String?;
    final cdc = detected['cdcSifen'] as String?;
    return OcrResultEntity(
      amount: (detected['monto'] as num?)?.toDouble() ?? 0,
      date: rawDate == null ? DateTime.now() : DateTime.parse(rawDate),
      merchant: detected['comercio'] as String? ?? '',
      suggestedCategoryId: detected['categoriaSugeridaId'] as String? ?? '',
      confidence: (json['confianza'] as num?)?.toDouble() ?? 0,
      status: _status(json['estado'] as String),
      source: source,
      documentReference: cdc ?? documentId,
      documentPath: documentPath,
      documentName: documentName,
      documentId: documentId,
      processingId: json['id'] as String,
      processingVersion: (json['version'] as num).toInt(),
      warnings: warnings,
    );
  }

  (String, String) _metadata(OcrSource source, String name) {
    switch (source) {
      case OcrSource.pdf:
        return ('pdf', 'application/pdf');
      case OcrSource.xml:
        return ('xml-sifen', 'application/xml');
      case OcrSource.camera:
      case OcrSource.gallery:
        final lower = name.toLowerCase();
        if (lower.endsWith('.png')) return ('imagen', 'image/png');
        if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          return ('imagen', 'image/jpeg');
        }
        throw const AppFailure(
          'La imagen debe estar en formato JPG o PNG.',
          code: 'unsupported_image_format',
        );
    }
  }

  OcrStatus _status(String value) => switch (value) {
    'pendiente' => OcrStatus.pending,
    'procesando' => OcrStatus.processing,
    'completado' => OcrStatus.success,
    'incompleto' => OcrStatus.incomplete,
    _ => OcrStatus.failed,
  };

  String _warningForUser(String warning) {
    final normalized = warning.trim().toLowerCase();
    if (normalized.contains('fecha válida')) {
      return 'No se detectó una fecha válida. Completala manualmente.';
    }
    if (normalized.contains('total confiable')) {
      return 'No se detectó un total confiable. Completalo manualmente.';
    }
    if (normalized.contains('comercio')) {
      return 'No se detectó el comercio. Completalo manualmente.';
    }
    if (normalized.startsWith('amazon textract')) {
      return warning
          .replaceFirst(
            RegExp(r'^Amazon Textract\s*', caseSensitive: false),
            '',
          )
          .trimLeft();
    }
    return warning;
  }

  String _key(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
