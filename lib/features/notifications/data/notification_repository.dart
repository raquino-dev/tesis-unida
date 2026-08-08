import 'dart:io';

import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/pilot_local_store.dart';

class NotificationPreferences {
  final bool pushEnabled;
  final bool weeklySummary;

  const NotificationPreferences({
    required this.pushEnabled,
    required this.weeklySummary,
  });
}

class NotificationRepository {
  final ApiClient _api;
  final bool _useApi;

  NotificationRepository(this._api, {bool? useApi})
    : _useApi = useApi ?? AppEnvironment.useApi;

  Future<NotificationPreferences> getPreferences() async {
    if (!_useApi) {
      return NotificationPreferences(
        pushEnabled: PilotLocalStore.pushNotifications,
        weeklySummary: PilotLocalStore.weeklySummary,
      );
    }
    final json = (await _api.get('/perfil/preferencias')).object;
    final preferences = NotificationPreferences(
      pushEnabled: json['notificacionesPush'] as bool? ?? true,
      weeklySummary: json['resumenSemanal'] as bool? ?? false,
    );
    await PilotLocalStore.savePushNotifications(preferences.pushEnabled);
    await PilotLocalStore.saveWeeklySummary(preferences.weeklySummary);
    return preferences;
  }

  Future<NotificationPreferences> updatePreferences({
    required bool pushEnabled,
    required bool weeklySummary,
  }) async {
    if (_useApi) {
      final current = await _api.get('/perfil/preferencias');
      final json = current.object;
      final version = (json['version'] as num).toInt();
      await _api.put(
        '/perfil/preferencias',
        headers: {'If-Match': '"$version"'},
        body: {
          'tema': json['tema'] as String? ?? 'oscuro',
          'idioma': json['idioma'] as String? ?? 'es',
          'notificacionesPush': pushEnabled,
          'resumenSemanal': weeklySummary,
        },
      );
    }
    await PilotLocalStore.savePushNotifications(pushEnabled);
    await PilotLocalStore.saveWeeklySummary(weeklySummary);
    return NotificationPreferences(
      pushEnabled: pushEnabled,
      weeklySummary: weeklySummary,
    );
  }

  Future<void> registerPushToken(String token) async {
    if (!_useApi || !PilotLocalStore.hasSession) return;
    final storedId = PilotLocalStore.pushDeviceId;
    final storedVersion = PilotLocalStore.pushDeviceVersion;
    if (storedId != null && storedVersion != null) {
      try {
        final response = await _api.patch(
          '/dispositivos/$storedId',
          headers: {'If-Match': '"$storedVersion"'},
          body: {
            'nombre': 'Aplicación móvil',
            'versionAplicacion': '0.1.0',
            'tokenPush': token,
            'zonaHoraria': DateTime.now().timeZoneName,
          },
        );
        await _saveDevice(response.object);
        return;
      } on AppFailure catch (failure) {
        if (failure.code != 'dispositivo_no_encontrado' &&
            failure.code != 'etag_desactualizado' &&
            failure.code != 'http_404' &&
            failure.code != 'http_412') {
          rethrow;
        }
      }
    }
    final response = await _api.post(
      '/dispositivos',
      body: {
        'identificadorInstalacion': AppEnvironment.deviceId,
        'nombre': 'Aplicación móvil',
        'plataforma': Platform.operatingSystem,
        'versionSistema': Platform.operatingSystemVersion,
        'versionAplicacion': '0.1.0',
        'tokenPush': token,
        'zonaHoraria': DateTime.now().timeZoneName,
      },
    );
    await _saveDevice(response.object);
  }

  Future<void> _saveDevice(Map<String, dynamic> json) =>
      PilotLocalStore.savePushDevice(
        id: json['id'] as String,
        version: (json['version'] as num).toInt(),
      );
}
