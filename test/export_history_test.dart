import 'dart:convert';
import 'dart:io';

import 'package:finanzas_app/core/network/api_client.dart';
import 'package:finanzas_app/features/export/data/api_export_repository.dart';
import 'package:finanzas_app/features/export/domain/export_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'el historial conserva formato, período y archivo descargable',
    () async {
      final id = 'export-${DateTime.now().microsecondsSinceEpoch}';
      final requests = <String>[];
      final api = ApiClient(
        httpClient: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.method == 'GET' &&
              request.url.path == '/api/v1/exportaciones') {
            return _json(200, {
              'datos': [
                {
                  'id': id,
                  'formato': 'pdf',
                  'estado': 'completado',
                  'desde': '2026-08-01',
                  'hasta': '2026-08-31',
                  'creadoEn': '2026-09-01T12:00:00Z',
                  'cantidadMovimientos': 12,
                  'totales': {
                    'ingresos': 5000000,
                    'gastos': 1200000,
                    'transferido': 300000,
                  },
                },
              ],
            });
          }
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/exportaciones/$id/descargas') {
            return _json(201, {
              'url': 'http://localhost:8080/files/$id.pdf',
              'expiraEn': '2026-09-01T12:10:00Z',
            });
          }
          if (request.method == 'GET' && request.url.path == '/files/$id.pdf') {
            return http.Response.bytes(
              utf8.encode('%PDF-1.4 test'),
              200,
              headers: {'content-type': 'application/pdf'},
            );
          }
          fail('Solicitud inesperada: ${request.method} ${request.url}');
        }),
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final repository = ApiExportRepository(api);

      final record = (await repository.getHistory()).single;
      final path = await repository.downloadExport(record);

      expect(record.format, ExportFormat.pdf);
      expect(record.range, '01/08/2026 - 31/08/2026');
      expect(record.date, DateTime.parse('2026-09-01T12:00:00Z').toLocal());
      expect(path, endsWith('.pdf'));
      expect(await File(path).readAsString(), startsWith('%PDF-1.4'));
      expect(requests, [
        'GET /api/v1/exportaciones',
        'POST /api/v1/exportaciones/$id/descargas',
        'GET /files/$id.pdf',
      ]);
    },
  );
}

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
