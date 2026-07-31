import '../../../../core/config/app_environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/pilot_local_store.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;

  ApiAuthRepository(this._api);

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    bool rememberDevice = true,
  }) async {
    final response = await _api.post(
      '/sesiones',
      authenticated: false,
      body: {
        'correo': email.trim(),
        'contrasena': password,
        'recordarDispositivo': rememberDevice,
        'dispositivo': {
          'identificador': AppEnvironment.deviceId,
          'nombre': 'Finanzas Inteligentes',
          'plataforma': 'android',
          'versionSistema': 'Android 10+',
          'versionAplicacion': '0.1.0',
        },
      },
    );
    await _api.saveSessionResponse(response.object);
    return currentUser();
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required bool acceptsTerms,
  }) async {
    await _api.post(
      '/usuarios',
      authenticated: false,
      body: {
        'correo': email.trim(),
        'nombre': name.trim(),
        'contrasena': password,
        'moneda': 'PYG',
        'idioma': 'es',
        'zonaHoraria': 'America/Asuncion',
        'aceptaTerminos': acceptsTerms,
        'versionPolitica': '1.0',
      },
    );
    return login(email: email, password: password);
  }

  @override
  Future<UserEntity> currentUser() async {
    final json = (await _api.get('/perfil')).object;
    return UserEntity(
      id: json['id'] as String,
      name: json['nombre'] as String,
      email: json['correo'] as String,
      currency: json['moneda'] as String? ?? 'PYG',
      language: json['idioma'] as String? ?? 'es',
      location: json['ubicacion'] as String? ?? 'Asunción',
    );
  }

  @override
  Future<void> sendPasswordRecovery({required String email}) async {
    await _api.post(
      '/recuperaciones-contrasena',
      authenticated: false,
      body: {'correo': email.trim()},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(
      '/restablecimientos-contrasena',
      authenticated: false,
      body: {'token': token.trim(), 'nuevaContrasena': newPassword},
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String otpVerificationId,
  }) async {
    await _api.put(
      '/perfil/contrasena',
      body: {
        'contrasenaActual': currentPassword,
        'nuevaContrasena': newPassword,
        'verificacionOtpId': otpVerificationId,
      },
    );
  }

  @override
  Future<void> deleteAccount({
    required String password,
    required String otpVerificationId,
  }) async {
    await _api.post(
      '/eliminaciones-perfil',
      body: {
        'contrasena': password,
        'verificacionOtpId': otpVerificationId,
      },
    );
  }

  @override
  Future<void> logout() async {
    final sessionId = await PilotLocalStore.readSessionId();
    if (sessionId != null) {
      try {
        await _api.delete('/sesiones/$sessionId');
      } catch (_) {
        // El cierre local debe completarse incluso si la sesión ya expiró.
      }
    }
    await PilotLocalStore.clearSession();
  }
}
