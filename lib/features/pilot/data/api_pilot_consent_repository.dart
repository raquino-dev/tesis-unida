import '../../../core/network/api_client.dart';

/// Finalidad específica del consentimiento informado de la prueba piloto.
/// Se mantiene separada del consentimiento de tratamiento de datos que se
/// registra durante el alta de una cuenta.
const pilotConsentPurpose = 'participacion-piloto';

class ApiPilotConsentRepository {
  ApiPilotConsentRepository(this._api);

  final ApiClient _api;

  Future<bool> hasActiveConsent() async {
    final policy = (await _api.get('/privacidad/politica-vigente')).object;
    final version = policy['version'] as String?;
    if (version == null || version.isEmpty) return false;

    final response = await _api.get('/privacidad/consentimientos');
    final consents = response.data as List<dynamic>? ?? const [];
    return consents.any((item) {
      final consent = item as Map<String, dynamic>;
      return consent['versionPolitica'] == version &&
          consent['finalidad'] == pilotConsentPurpose &&
          consent['revocadoEn'] == null;
    });
  }

  /// Registra la aceptación una sola vez por usuario, versión y finalidad.
  /// La comprobación previa evita crear filas duplicadas al reintentar.
  Future<void> accept() async {
    final policy = (await _api.get('/privacidad/politica-vigente')).object;
    final version = policy['version'] as String?;
    if (version == null || version.isEmpty) {
      throw const FormatException('No se encontró una política vigente.');
    }
    if (await hasActiveConsent()) return;

    await _api.post(
      '/privacidad/consentimientos',
      body: {'versionPolitica': version, 'finalidad': pilotConsentPurpose},
    );
  }
}
