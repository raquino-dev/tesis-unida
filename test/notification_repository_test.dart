import 'dart:convert';

import 'package:finanzas_app/core/network/api_client.dart';
import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await PilotLocalStore.clearSession();
    await PilotLocalStore.clearPushDevice();
  });

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

  test(
    'revoca el dispositivo push con su ETag y limpia el vínculo local',
    () async {
      await PilotLocalStore.savePushDevice(
        id: '5ea2014d-99ec-48a8-9422-27f87a8b2f19',
        version: 4,
      );
      late http.Request captured;
      final repository = NotificationRepository(
        ApiClient(
          httpClient: MockClient((request) async {
            captured = request;
            return http.Response('', 204);
          }),
          baseUrl: 'http://localhost:8080/api/v1',
        ),
        useApi: true,
      );

      await repository.unregisterPushDevice();

      expect(captured.method, 'DELETE');
      expect(
        captured.url.path,
        '/api/v1/dispositivos/5ea2014d-99ec-48a8-9422-27f87a8b2f19',
      );
      expect(captured.headers['if-match'], '"4"');
      expect(PilotLocalStore.pushDeviceId, isNull);
      expect(PilotLocalStore.pushDeviceVersion, isNull);
    },
  );

  test('limpia el vínculo local si el dispositivo ya fue revocado', () async {
    await PilotLocalStore.savePushDevice(id: 'missing', version: 2);
    final repository = NotificationRepository(
      ApiClient(
        httpClient: MockClient(
          (_) async => _json(404, {
            'title': 'No encontrado',
            'status': 404,
            'codigo': 'dispositivo_no_encontrado',
          }),
        ),
        baseUrl: 'http://localhost:8080/api/v1',
      ),
      useApi: true,
    );

    await repository.unregisterPushDevice();

    expect(PilotLocalStore.pushDeviceId, isNull);
    expect(PilotLocalStore.pushDeviceVersion, isNull);
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
