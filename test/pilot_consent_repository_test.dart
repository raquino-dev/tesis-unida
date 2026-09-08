import 'package:finanzas_app/core/network/api_client.dart';
import 'package:finanzas_app/features/pilot/data/api_pilot_consent_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('reconoce el consentimiento v2 activo de la política vigente', () async {
    final client = ApiClient(
      baseUrl: 'https://piloto.test/api/v1',
      httpClient: _FakeClient(finalidad: pilotConsentPurpose),
    );
    final repository = ApiPilotConsentRepository(client);

    expect(await repository.hasActiveConsent(), isTrue);
    client.close();
  });

  test('la aceptación anterior no evita solicitar el consentimiento v2', () async {
    final client = ApiClient(
      baseUrl: 'https://piloto.test/api/v1',
      httpClient: _FakeClient(finalidad: 'participacion-piloto'),
    );
    final repository = ApiPilotConsentRepository(client);

    expect(await repository.hasActiveConsent(), isFalse);
    client.close();
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.finalidad});

  final String finalidad;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/api/v1/privacidad/politica-vigente' => '{"version":"1.0"}',
      '/api/v1/privacidad/consentimientos' =>
        '[{"versionPolitica":"1.0","finalidad":"$finalidad","revocadoEn":null}]',
      _ => '{}',
    };
    return http.StreamedResponse(
      Stream.value(body.codeUnits),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
