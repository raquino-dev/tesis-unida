import 'dart:convert';

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

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
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

  static Future<void> saveSession(String refreshToken) async {
    await _setBool(_sessionKey, true);
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Los tests de widget y plataformas sin almacén seguro siguen usando el
      // indicador en memoria. La API real nunca debe caer a texto plano.
    }
  }

  static Future<void> clearSession() async {
    await _setBool(_sessionKey, false);
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }

  static bool get consentAccepted => _getBool(_consentKey);
  static Future<void> acceptConsent() => _setBool(_consentKey, true);

  static bool get preSurveyCompleted => _getBool(_preSurveyKey);
  static bool get postSurveyCompleted => _getBool(_postSurveyKey);
  static Future<void> completePreSurvey() => _setBool(_preSurveyKey, true);
  static Future<void> completePostSurvey() => _setBool(_postSurveyKey, true);

  static bool get darkTheme => _getBool(_themeDarkKey, fallback: true);
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
