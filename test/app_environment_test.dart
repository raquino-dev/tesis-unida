import 'package:finanzas_app/core/config/app_environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa un App ID específico para Android', () {
    expect(
      AppEnvironment.firebaseAppIdFor(TargetPlatform.android),
      AppEnvironment.firebaseAndroidAppId,
    );
    expect(AppEnvironment.firebaseAndroidAppId, isNotEmpty);
  });

  test('no reutiliza silenciosamente el App ID Android en iOS', () {
    final iosAppId = AppEnvironment.firebaseAppIdFor(TargetPlatform.iOS);

    expect(iosAppId, AppEnvironment.firebaseIosAppId);
    expect(iosAppId, isNot(AppEnvironment.firebaseAndroidAppId));
  });
}
