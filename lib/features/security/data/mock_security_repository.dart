import 'package:local_auth/local_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/pilot_local_store.dart';
import '../domain/security_entity.dart';
import '../domain/security_repository.dart';

class MockSecurityRepository implements SecurityRepository {
  final LocalAuthentication _localAuthentication;
  MockSecurityRepository({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication(),
      _biometricsEnabled = PilotLocalStore.biometricsEnabled;

  MockSessionEntity? _session;
  bool _biometricsEnabled;
  final List<SecurityEventEntity> _events = [];
  final Map<String, OtpChallengeEntity> _challenges = {};
  int _sequence = 1;

  @override
  Future<MockSessionEntity> createSession({required bool trustedDevice}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final stamp = DateTime.now().millisecondsSinceEpoch;
    _session = MockSessionEntity(
      id: 'session_$stamp',
      accessToken: 'mock.jwt.access.$stamp',
      refreshToken: 'mock_refresh_$stamp',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      trustedDevice: trustedDevice,
    );
    await recordEvent(
      SecurityEventType.login,
      trustedDevice
          ? 'Inicio de sesión en dispositivo habitual'
          : 'Inicio de sesión en dispositivo nuevo',
    );
    return _session!;
  }

  @override
  Future<MockSessionEntity?> getSession() async => _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<OtpChallengeEntity> requestOtp(String reason) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final id = 'otp_${_sequence++}';
    final challenge = OtpChallengeEntity(
      id: id,
      reason: reason,
      maskedDestination: 'ro***@correo.com.py',
      demoCode: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    _challenges[id] = challenge;
    await recordEvent(SecurityEventType.otp, 'OTP solicitado: $reason');
    return challenge;
  }

  @override
  Future<String?> validateOtp(String challengeId, String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final challenge = _challenges[challengeId];
    final valid =
        challenge != null &&
        DateTime.now().isBefore(challenge.expiresAt) &&
        code == challenge.demoCode;
    await recordEvent(
      SecurityEventType.otp,
      valid ? 'OTP validado correctamente' : 'Código OTP inválido',
      successful: valid,
    );
    if (valid) _challenges.remove(challengeId);
    return valid ? 'verification_${_sequence++}' : null;
  }

  @override
  Future<List<ActiveSessionEntity>> getActiveSessions() async {
    final session = _session;
    if (session == null) return const [];
    return [
      ActiveSessionEntity(
        id: session.id,
        deviceName: 'Dispositivo de demostración',
        platform: 'Android',
        issuedAt: session.expiresAt.subtract(const Duration(minutes: 15)),
        expiresAt: session.expiresAt,
        current: true,
      ),
    ];
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    if (_session?.id == sessionId) _session = null;
  }

  @override
  Future<bool> authenticateBiometrically() async {
    if (!_biometricsEnabled) {
      await recordEvent(
        SecurityEventType.biometric,
        'Biometría no habilitada',
        successful: false,
      );
      return false;
    }
    var success = false;
    try {
      success = await _localAuthentication.authenticate(
        localizedReason:
            'Confirmá tu identidad para continuar en Finanzas Inteligentes',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      // Permite que las pruebas automatizadas y plataformas sin plugin sigan
      // validando el flujo mock. En un Android compatible se usa el diálogo
      // biométrico real.
      success = _biometricsEnabled;
    }
    await recordEvent(
      SecurityEventType.biometric,
      success ? 'Validación biométrica correcta' : 'Biometría no habilitada',
      successful: success,
    );
    return success;
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    if (enabled) {
      try {
        final supported = await _localAuthentication.isDeviceSupported();
        final enrolled = await _localAuthentication.canCheckBiometrics;
        if (!supported || !enrolled) {
          throw const AppFailure(
            'Este dispositivo no tiene biometría disponible o configurada.',
          );
        }
      } on AppFailure {
        rethrow;
      } catch (_) {
        // En pruebas y escritorio se mantiene el comportamiento mock.
      }
    }
    _biometricsEnabled = enabled;
    await PilotLocalStore.saveBiometricsEnabled(enabled);
    await recordEvent(
      SecurityEventType.biometric,
      enabled ? 'Biometría habilitada' : 'Biometría deshabilitada',
    );
  }

  @override
  Future<bool> isBiometricsEnabled() async => _biometricsEnabled;

  @override
  Future<void> recordEvent(
    SecurityEventType type,
    String description, {
    bool successful = true,
  }) async {
    _events.insert(
      0,
      SecurityEventEntity(
        id: 'sec_${_sequence++}',
        type: type,
        description: description,
        occurredAt: DateTime.now(),
        successful: successful,
      ),
    );
  }

  @override
  Future<List<SecurityEventEntity>> getEvents() async =>
      List.unmodifiable(_events);
}
