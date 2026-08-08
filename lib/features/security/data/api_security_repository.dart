import 'package:local_auth/local_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/pilot_local_store.dart';
import '../domain/security_entity.dart';
import '../domain/security_repository.dart';

class ApiSecurityRepository implements SecurityRepository {
  final ApiClient _api;
  final LocalAuthentication _localAuthentication;

  ApiSecurityRepository(
    this._api, {
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  @override
  Future<MockSessionEntity> createSession({
    required bool trustedDevice,
  }) async {
    throw const AppFailure(
      'La sesión real se crea durante el inicio de sesión.',
      code: 'session_already_created',
    );
  }

  @override
  Future<MockSessionEntity?> getSession() async => null;

  @override
  Future<void> clearSession() => PilotLocalStore.clearSession();

  @override
  Future<OtpChallengeEntity> requestOtp(String reason) async {
    final normalizedReason = _normalizeReason(reason);
    final json = (await _api.post(
      '/desafios-otp',
      body: {'motivo': normalizedReason, 'canal': 'correo'},
    ))
        .object;
    return OtpChallengeEntity(
      id: json['id'] as String,
      reason: normalizedReason,
      maskedDestination: json['destinoEnmascarado'] as String,
      expiresAt: DateTime.parse(json['expiraEn'] as String).toLocal(),
    );
  }

  @override
  Future<String?> validateOtp(String challengeId, String code) async {
    try {
      final json = (await _api.post(
        '/verificaciones-otp',
        body: {'desafioId': challengeId, 'codigo': code},
      ))
          .object;
      return json['valida'] == true ? json['id'] as String : null;
    } on AppFailure catch (failure) {
      if (const {
        'otp_invalido',
        'otp_expirado',
        'otp_bloqueado',
        'otp_utilizado',
      }.contains(failure.code)) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<ActiveSessionEntity>> getActiveSessions() async {
    final json = (await _api.get('/sesiones')).object;
    final data = (json['datos'] as List? ?? const []);
    return data.map((item) {
      final value = item as Map<String, dynamic>;
      final device = value['dispositivo'] as Map<String, dynamic>? ?? const {};
      return ActiveSessionEntity(
        id: value['id'] as String,
        deviceName: device['nombre'] as String? ?? 'Dispositivo desconocido',
        platform: device['plataforma'] as String? ?? 'desconocida',
        issuedAt: DateTime.parse(value['emitidaEn'] as String).toLocal(),
        expiresAt: DateTime.parse(value['expiraEn'] as String).toLocal(),
        current: value['actual'] as bool? ?? false,
      );
    }).toList(growable: false);
  }

  @override
  Future<void> revokeSession(String sessionId) =>
      _api.delete('/sesiones/$sessionId');

  @override
  Future<bool> authenticateBiometrically() async {
    if (!PilotLocalStore.biometricsEnabled) return false;
    try {
      final result = await _localAuthentication.authenticate(
        localizedReason:
            'Confirmá tu identidad para continuar en Finanzas Inteligentes',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      await PilotLocalStore.recordMetric(
        'biometric_reauthentication',
        data: {'successful': result},
      );
      return result;
    } catch (_) {
      await PilotLocalStore.recordMetric(
        'biometric_reauthentication',
        data: {'successful': false},
      );
      return false;
    }
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    if (enabled) {
      final supported = await _localAuthentication.isDeviceSupported();
      final enrolled = await _localAuthentication.canCheckBiometrics;
      if (!supported || !enrolled) {
        throw const AppFailure(
          'Este dispositivo no tiene biometría disponible o configurada.',
        );
      }
      final verified = await _localAuthentication.authenticate(
        localizedReason:
            'Verificá tu identidad para habilitar el acceso biométrico',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!verified) {
        throw const AppFailure('No se pudo verificar tu identidad.');
      }
    }
    await PilotLocalStore.saveBiometricsEnabled(enabled);
  }

  @override
  Future<bool> isBiometricsEnabled() async =>
      PilotLocalStore.biometricsEnabled;

  @override
  Future<void> recordEvent(
    SecurityEventType type,
    String description, {
    bool successful = true,
  }) async {
    // En modo API los eventos confiables se generan en el servidor.
  }

  @override
  Future<List<SecurityEventEntity>> getEvents() async {
    final json = (await _api.get('/eventos-seguridad?limite=50')).object;
    final data = (json['datos'] as List? ?? const []);
    return data.map((item) {
      final value = item as Map<String, dynamic>;
      return SecurityEventEntity(
        id: value['id'] as String,
        type: _eventType(value['tipo'] as String? ?? ''),
        description: value['descripcion'] as String? ?? 'Evento de seguridad',
        occurredAt: DateTime.parse(value['ocurridoEn'] as String).toLocal(),
        successful: value['exitoso'] as bool? ?? false,
      );
    }).toList(growable: false);
  }

  String _normalizeReason(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('cambio') && normalized.contains('contraseña')) {
      return 'cambio-contrasena';
    }
    if (normalized.contains('grupo') &&
        (normalized.contains('eliminar') ||
            normalized.contains('eliminación'))) {
      return 'eliminacion-grupo-familiar';
    }
    if (normalized.contains('eliminar') || normalized.contains('eliminación')) {
      return 'eliminacion-perfil';
    }
    if (normalized == 'cambio-contrasena' ||
        normalized == 'eliminacion-perfil' ||
        normalized == 'eliminacion-grupo-familiar' ||
        normalized == 'operacion-sensible') {
      return normalized;
    }
    return 'operacion-sensible';
  }

  SecurityEventType _eventType(String value) {
    if (value.contains('otp')) return SecurityEventType.otp;
    if (value.contains('contrasena')) return SecurityEventType.passwordChange;
    if (value.contains('biometr')) return SecurityEventType.biometric;
    if (value.contains('fallido')) return SecurityEventType.failedLogin;
    if (value.contains('sesion') || value.contains('login')) {
      return SecurityEventType.login;
    }
    return SecurityEventType.criticalAction;
  }
}
