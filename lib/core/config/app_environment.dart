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

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
