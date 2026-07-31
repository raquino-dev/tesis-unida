import 'dart:convert';

import 'package:finanzas_app/core/network/api_client.dart';
import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PilotLocalStore.clearSession);

  test('sincroniza preferencias push usando el ETag del backend', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return _json(
          200,
          {
            'tema': 'oscuro',
            'idioma': 'es',
            'notificacionesPush': true,
            'resumenSemanal': false,
            'version': 7,
          },
          headers: {'etag': '"7"'},
        );
      }
      expect(request.method, 'PUT');
      expect(request.headers['if-match'], '"7"');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['notificacionesPush'], false);
      expect(body['resumenSemanal'], true);
      return _json(200, {...body, 'version': 8});
    });
    final repository = NotificationRepository(
      ApiClient(httpClient: client, baseUrl: 'http://localhost:8080/api/v1'),
      useApi: true,
    );

    final result = await repository.updatePreferences(
      pushEnabled: false,
      weeklySummary: true,
    );

    expect(result.pushEnabled, false);
    expect(result.weeklySummary, true);
    expect(requests.map((request) => request.method), ['GET', 'PUT']);
  });
}

http.Response _json(
  int status,
  Object body, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...headers},
);
