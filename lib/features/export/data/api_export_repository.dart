import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_formatter.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../domain/export_entity.dart';
import '../domain/export_repository.dart';

class ApiExportRepository implements ExportRepository {
  final ApiClient _api;

  ApiExportRepository(this._api);

  @override
  Future<List<ExportRecord>> getHistory() async {
    final page = (await _api.get('/exportaciones')).object;
    return Future.wait(
      (page['datos'] as List<dynamic>? ?? const []).map((item) async {
        final json = item as Map<String, dynamic>;
        final format = _formatFromJson(json);
        final file = await _artifactFile(json['id'] as String, format);
        return _fromJson(
          json,
          artifactPath: await file.exists() ? file.path : null,
        );
      }),
    );
  }

  @override
  Future<String> downloadExport(ExportRecord record) async {
    final currentPath = record.artifactPath;
    if (currentPath != null && await File(currentPath).exists()) {
      return currentPath;
    }
    return _downloadArtifact(record.id, record.format);
  }

  @override
  Future<ExportRecord> requestExport({
    required ExportFormat format,
    required DateTimeRange range,
    required MovementFilters filters,
    required String filtersSummary,
  }) async {
    final response = await _api.post(
      '/exportaciones',
      headers: {'Idempotency-Key': _key()},
      body: {
        'formato': format == ExportFormat.pdf ? 'pdf' : 'xlsx',
        'ambito': 'privado',
        'grupoFamiliarId': null,
        'desde': _date(range.start),
        'hasta': _date(range.end),
        'filtros': {
          'tipo': switch (filters.type) {
            MovementType.income => 'ingreso',
            MovementType.expense => 'gasto',
            null => null,
          },
          'categoriaId': filters.categoryId,
          'cuentaId': filters.accountId,
          'documento': switch (filters.ocrFilter) {
            OcrFilter.withOcr => 'con-documento',
            OcrFilter.withoutOcr => 'sin-documento',
            OcrFilter.any => 'cualquiera',
          },
        },
      },
    );
    final completed = await _waitForExport(response.object['id'] as String);
    final path = await _downloadArtifact(completed['id'] as String, format);
    return _fromJson(
      completed,
      range: range,
      filtersSummary: filtersSummary,
      artifactPath: path,
    );
  }

  Future<String> _downloadArtifact(String id, ExportFormat format) async {
    final download = (await _api.post('/exportaciones/$id/descargas')).object;
    final bytes = await _api.downloadBytes(download['url'] as String);
    final file = await _artifactFile(id, format);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<File> _artifactFile(String id, ExportFormat format) async {
    Directory root;
    try {
      root = await getApplicationDocumentsDirectory();
    } catch (_) {
      root = Directory.systemTemp;
    }
    final directory = Directory('${root.path}/extractos');
    await directory.create(recursive: true);
    final extension = format == ExportFormat.pdf ? 'pdf' : 'xlsx';
    return File('${directory.path}/finanzas_$id.$extension');
  }

  Future<Map<String, dynamic>> _waitForExport(String id) async {
    for (var attempt = 0; attempt < 24; attempt++) {
      final json = (await _api.get('/exportaciones/$id')).object;
      final state = json['estado'] as String;
      if (state == 'completado') return json;
      if (state == 'fallido') {
        throw const AppFailure(
          'La exportación no pudo generarse.',
          code: 'export_failed',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
    throw const AppFailure(
      'La exportación continúa procesándose. Revisá el historial en unos segundos.',
      code: 'export_processing_timeout',
    );
  }

  ExportRecord _fromJson(
    Map<String, dynamic> json, {
    DateTimeRange? range,
    String filtersSummary = 'Filtros guardados en el servidor',
    String? artifactPath,
  }) {
    final createdAt = DateTime.parse(json['creadoEn'] as String).toLocal();
    final from = _periodDate(json, 'desde');
    final to = _periodDate(json, 'hasta');
    final totals =
        json['totales'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return ExportRecord(
      id: json['id'] as String,
      format: _formatFromJson(json),
      range: range != null
          ? '${DateFormatter.short(range.start)} - ${DateFormatter.short(range.end)}'
          : from != null && to != null
          ? '${DateFormatter.short(from)} - ${DateFormatter.short(to)}'
          : 'Período no disponible',
      date: createdAt,
      success: json['estado'] == 'completado',
      totalIncome: (totals['ingresos'] as num?)?.toDouble() ?? 0,
      totalExpense: (totals['gastos'] as num?)?.toDouble() ?? 0,
      totalTransferred: (totals['transferido'] as num?)?.toDouble() ?? 0,
      movementCount: (json['cantidadMovimientos'] as num?)?.toInt() ?? 0,
      filtersSummary: filtersSummary,
      artifactPath: artifactPath,
    );
  }

  ExportFormat _formatFromJson(Map<String, dynamic> json) =>
      json['formato'] == 'pdf' ? ExportFormat.pdf : ExportFormat.excel;

  DateTime? _periodDate(Map<String, dynamic> json, String key) {
    final period = json['periodo'];
    final value =
        json[key] ?? (period is Map<String, dynamic> ? period[key] : null);
    return value is String ? DateTime.tryParse(value) : null;
  }

  String _key() => 'export-${DateTime.now().microsecondsSinceEpoch}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
