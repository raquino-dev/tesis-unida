import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';

/// Finalidad específica del consentimiento informado de la prueba piloto.
///
/// La versión v2 corresponde al consentimiento actualizado que explicita una
/// ventana de observación de 28 días por unidad familiar. Se mantiene separada
/// de la aceptación general de la política de privacidad y permite conservar
/// trazabilidad de la aceptación anterior sin sobrescribirla.
const pilotConsentPurpose = 'participacion-piloto-v2';

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

  /// Registra la aceptación una sola vez por usuario, versión de política y
  /// finalidad de participación. La finalidad versionada permite solicitar una
  /// nueva aceptación sin destruir el registro histórico de la versión previa.
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
      offline: OfflineMutation(
        entityType: 'consentimiento',
        entityId: '$pilotConsentPurpose:$version',
        optimisticResponse: const <String, dynamic>{},
      ),
    );
  }
}
