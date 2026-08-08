import 'package:firebase_core/firebase_core.dart';

import 'app_environment.dart';

/// Configuración pública del proyecto Firebase del piloto.
///
/// Las claves privadas, archivos de cuentas de servicio y los ficheros
/// específicos de plataforma permanecen fuera del repositorio. Los valores
/// que se usan aquí son identificadores de cliente y pueden sobrescribirse
/// mediante `--dart-define` cuando sea necesario.
class PilotFirebaseOptions {
  PilotFirebaseOptions._();

  static FirebaseOptions get current => FirebaseOptions(
    apiKey: AppEnvironment.firebaseApiKey,
    appId: AppEnvironment.firebaseAppId,
    messagingSenderId: AppEnvironment.firebaseMessagingSenderId,
    projectId: AppEnvironment.firebaseProjectId,
  );
}
