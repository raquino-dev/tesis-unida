import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia mínima necesaria para que la beta piloto se comporte como una
/// aplicación instalada, aun mientras los datos financieros sigan siendo mock.
///
/// Los datos sensibles se guardan en [FlutterSecureStorage]. Preferencias,
/// consentimiento y métricas de uso no sensibles se guardan con
/// [SharedPreferences].
class PilotLocalStore {
  PilotLocalStore._();

  static SharedPreferences? _preferences;
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, Object> _memory = {};

  static const _onboardingKey = 'pilot.onboarding.completed';
  static const _sessionKey = 'pilot.session.active';
  static const _refreshTokenKey = 'pilot.refresh.token';
  static const _accessTokenKey = 'pilot.access.token';
  static const _sessionIdKey = 'pilot.session.id';
  static const _consentKey = 'pilot.consent.accepted';
  static const _preSurveyKey = 'pilot.survey.pre.completed';
  static const _postSurveyKey = 'pilot.survey.post.completed';
  static const _themeDarkKey = 'pilot.theme.dark';
  static const _biometricsKey = 'pilot.biometrics.enabled';
  static const _ocrMonthKey = 'pilot.ocr.month';
  static const _ocrCountKey = 'pilot.ocr.count';
  static const _metricsKey = 'pilot.metrics';
  static const _planKey = 'pilot.subscription.plan';
  static const _pushKey = 'pilot.notifications.push';
  static const _weeklyKey = 'pilot.notifications.weekly';
  static const _pushDeviceIdKey = 'pilot.notifications.device.id';
  static const _pushDeviceVersionKey = 'pilot.notifications.device.version';
  static const _installationIdKey = 'pilot.installation.id';
  static const _lastOnlineAuthenticationKey = 'pilot.auth.last_online';

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Identificador aleatorio y estable de esta instalación.
  ///
  /// No utiliza datos del dispositivo y permite que cada tester mantenga sus
  /// sesiones y token FCM aislados de los demás.
  static Future<String> installationId() async {
    final existing =
        _preferences?.getString(_installationIdKey) ??
        _memory[_installationIdKey] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    _memory[_installationIdKey] = value;
    await _preferences?.setString(_installationIdKey, value);
    return value;
  }

  static bool _getBool(String key, {bool fallback = false}) {
    return _preferences?.getBool(key) ?? _memory[key] as bool? ?? fallback;
  }

  static Future<void> _setBool(String key, bool value) async {
    _memory[key] = value;
    await _preferences?.setBool(key, value);
  }

  static bool get onboardingCompleted => _getBool(_onboardingKey);
  static Future<void> completeOnboarding() => _setBool(_onboardingKey, true);

  static bool get hasSession => _getBool(_sessionKey);

  static bool get offlineSessionValid {
    if (!hasSession) return false;
    final raw = _preferences?.getString(_lastOnlineAuthenticationKey);
    if (raw == null) return true; // Compatibilidad con instalaciones previas.
    final timestamp = DateTime.tryParse(raw);
    if (timestamp == null) return false;
    return DateTime.now().toUtc().difference(timestamp.toUtc()) <=
        const Duration(days: 7);
  }

  static Future<void> markOnlineAuthentication() async {
    await _preferences?.setString(
      _lastOnlineAuthenticationKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<void> saveSession(String refreshToken) async {
    await _setBool(_sessionKey, true);
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Los tests de widget y plataformas sin almacén seguro siguen usando el
      // indicador en memoria. La API real nunca debe caer a texto plano.
    }
  }

  static Future<void> saveApiSession({
    required String accessToken,
    required String refreshToken,
    required String sessionId,
  }) async {
    await _setBool(_sessionKey, true);
    await markOnlineAuthentication();
    try {
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
        _secureStorage.write(key: _sessionIdKey, value: sessionId),
      ]);
    } catch (_) {
      _memory[_accessTokenKey] = accessToken;
      _memory[_refreshTokenKey] = refreshToken;
      _memory[_sessionIdKey] = sessionId;
    }
  }

  static Future<String?> readAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (_) {
      return _memory[_accessTokenKey] as String?;
    }
  }

  static Future<String?> readRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (_) {
      return _memory[_refreshTokenKey] as String?;
    }
  }

  static Future<String?> readSessionId() async {
    try {
      return await _secureStorage.read(key: _sessionIdKey);
    } catch (_) {
      return _memory[_sessionIdKey] as String?;
    }
  }

  /// Clave estable y no reversible para aislar la información financiera
  /// almacenada localmente. Se deriva del sujeto del JWT y nunca persiste el
  /// identificador del usuario en texto plano.
  static Future<String?> currentUserStorageKey() async {
    final accessToken = await readAccessToken();
    if (accessToken != null) {
      try {
        final parts = accessToken.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final subject = json['sub']?.toString();
          if (subject != null && subject.isNotEmpty) {
            return _storageHash(subject);
          }
        }
      } catch (_) {
        // Un token de demostración puede no ser un JWT. Se usa la sesión como
        // alternativa sin exponerla en la base local.
      }
    }
    final sessionId = await readSessionId();
    if (sessionId == null || sessionId.isEmpty) return null;
    return _storageHash(sessionId);
  }

  static String _storageHash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static Future<void> clearSession() async {
    await _setBool(_sessionKey, false);
    await _preferences?.remove(_lastOnlineAuthenticationKey);
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _sessionIdKey),
      ]);
    } catch (_) {
      _memory.remove(_accessTokenKey);
      _memory.remove(_refreshTokenKey);
      _memory.remove(_sessionIdKey);
    }
  }

  static bool get consentAccepted => _getBool(_consentKey);
  static Future<void> acceptConsent() => _setBool(_consentKey, true);

  static bool get preSurveyCompleted => _getBool(_preSurveyKey);
  static bool get postSurveyCompleted => _getBool(_postSurveyKey);
  static Future<void> completePreSurvey() => _setBool(_preSurveyKey, true);
  static Future<void> completePostSurvey() => _setBool(_postSurveyKey, true);

  static bool get darkTheme => _getBool(_themeDarkKey, fallback: false);
  static Future<void> saveDarkTheme(bool enabled) =>
      _setBool(_themeDarkKey, enabled);

  static bool get biometricsEnabled => _getBool(_biometricsKey);
  static Future<void> saveBiometricsEnabled(bool enabled) =>
      _setBool(_biometricsKey, enabled);

  static String get subscriptionPlan =>
      _preferences?.getString(_planKey) ??
      _memory[_planKey] as String? ??
      'free';
  static Future<void> saveSubscriptionPlan(String plan) async {
    _memory[_planKey] = plan;
    await _preferences?.setString(_planKey, plan);
  }

  static bool get pushNotifications => _getBool(_pushKey, fallback: true);
  static bool get weeklySummary => _getBool(_weeklyKey);
  static Future<void> savePushNotifications(bool enabled) =>
      _setBool(_pushKey, enabled);
  static Future<void> saveWeeklySummary(bool enabled) =>
      _setBool(_weeklyKey, enabled);

  static String? get pushDeviceId =>
      _preferences?.getString(_pushDeviceIdKey) ??
      _memory[_pushDeviceIdKey] as String?;
  static int? get pushDeviceVersion =>
      _preferences?.getInt(_pushDeviceVersionKey) ??
      _memory[_pushDeviceVersionKey] as int?;
  static Future<void> savePushDevice({
    required String id,
    required int version,
  }) async {
    _memory[_pushDeviceIdKey] = id;
    _memory[_pushDeviceVersionKey] = version;
    await _preferences?.setString(_pushDeviceIdKey, id);
    await _preferences?.setInt(_pushDeviceVersionKey, version);
  }

  static Future<void> clearPushDevice() async {
    _memory.remove(_pushDeviceIdKey);
    _memory.remove(_pushDeviceVersionKey);
    await Future.wait([
      _preferences?.remove(_pushDeviceIdKey) ?? Future.value(false),
      _preferences?.remove(_pushDeviceVersionKey) ?? Future.value(false),
    ]);
  }

  static int get monthlyOcrCount {
    _resetOcrCounterIfNeeded();
    return _preferences?.getInt(_ocrCountKey) ??
        _memory[_ocrCountKey] as int? ??
        0;
  }

  static bool get hasFreeOcrQuota => monthlyOcrCount < 3;

  static Future<int> registerOcrUse() async {
    _resetOcrCounterIfNeeded();
    final next = monthlyOcrCount + 1;
    _memory[_ocrCountKey] = next;
    await _preferences?.setInt(_ocrCountKey, next);
    return next;
  }

  static void _resetOcrCounterIfNeeded() {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final storedMonth =
        _preferences?.getString(_ocrMonthKey) ??
        _memory[_ocrMonthKey] as String?;
    if (storedMonth == month) return;
    _memory[_ocrMonthKey] = month;
    _memory[_ocrCountKey] = 0;
    _preferences?.setString(_ocrMonthKey, month);
    _preferences?.setInt(_ocrCountKey, 0);
  }

  static Future<void> recordMetric(
    String name, {
    Map<String, Object?> data = const {},
  }) async {
    final metrics = getMetrics().toList();
    metrics.add({
      'name': name,
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
    final encoded = jsonEncode(metrics.takeLast(500).toList());
    _memory[_metricsKey] = encoded;
    await _preferences?.setString(_metricsKey, encoded);
  }

  static List<Map<String, dynamic>> getMetrics() {
    final encoded =
        _preferences?.getString(_metricsKey) ?? _memory[_metricsKey] as String?;
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      return (jsonDecode(encoded) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }
}

extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final values = toList();
    return values.skip(values.length > count ? values.length - count : 0);
  }
}
