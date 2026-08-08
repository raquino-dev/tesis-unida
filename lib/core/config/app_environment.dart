class AppEnvironment {
  AppEnvironment._();

  static const useApi = bool.fromEnvironment(
    'USE_REAL_API',
    defaultValue: false,
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const deviceId = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'finanzas-flutter',
  );

  static const googlePlayMonthlyProductId = String.fromEnvironment(
    'GOOGLE_PLAY_MONTHLY_PRODUCT_ID',
    defaultValue: 'premium_monthly',
  );

  static const googlePlayAnnualProductId = String.fromEnvironment(
    'GOOGLE_PLAY_ANNUAL_PRODUCT_ID',
    defaultValue: 'premium_yearly',
  );

  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyCM77v5DU2sSA4j_UTwBov5nMTfY6EGCS4',
  );
  static const firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:874909933539:android:885f26c9a43616ab4dcad6',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '874909933539',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'finanzas-piloto-ra-2026',
  );

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
