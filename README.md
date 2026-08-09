# Finanzas Inteligentes

Aplicación Flutter para la gestión de finanzas personales y familiares. Puede
ejecutarse con repositorios mock para demostraciones aisladas o conectada a la
API ASP.NET Core mediante parámetros de compilación.

Las [decisiones aprobadas del piloto](docs/DECISIONES_PILOTO.md) fijan el alcance
móvil, Google Play Billing de prueba, Firebase Cloud Messaging y la prohibición
de recopilar datos del plástico de tarjetas.

## Identidad Android

- Application ID: `com.tesis.finanzasinteligentes`
- Nombre visible: `Finanzas Inteligentes`
- Versión: `0.1.0+3`

## Verificación local

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Integración con la API

El modo mock continúa siendo el predeterminado para que las pruebas y las
demostraciones sin infraestructura sigan funcionando.

Para usar el backend desde un emulador Android:

```bash
flutter run \
  --dart-define=USE_REAL_API=true \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Desde un dispositivo físico, reemplazá `10.0.2.2` por la IP local del equipo
que ejecuta Docker. Para un backend desplegado se debe utilizar una URL HTTPS:

```bash
flutter run \
  --dart-define=USE_REAL_API=true \
  --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
```

El modo API integra registro, sesión y renovación de tokens, recuperación y
cambio de contraseña con OTP, sesiones activas, eventos de seguridad, perfil,
cuentas, categorías, movimientos, tarjetas por alias, transferencias internas,
recurrencias, presupuestos privados y familiares, metas privadas y compartidas,
grupos familiares, integrantes, invitaciones, cuentas compartidas, movimientos
familiares, operaciones de caja, carga documental, XML SIFEN, corrección de
datos detectados, exportaciones PDF/XLSX descargables, dashboard, reportes,
proyecciones, alertas explicables e indicador de salud financiera no crediticio.
También integra Google Play Billing para compra, restauración y cancelación de
suscripciones verificadas por el backend, y Firebase Cloud Messaging con
registro/renovación del token, preferencias y navegación desde la notificación.
Los tokens se almacenan con `flutter_secure_storage`; las actualizaciones usan los ETag requeridos por la
API. La biometría bloquea localmente la aplicación al iniciarla o reanudarla y
nunca transmite datos biométricos. El modo mock se conserva como alternativa
para demostraciones sin infraestructura.

## Google Play Billing y Firebase

Los productos del canal Internal testing deben coincidir con el mapeo del
backend (`premium_monthly` y `premium_yearly` por defecto). Se pueden cambiar
al compilar:

```bash
--dart-define=GOOGLE_PLAY_MONTHLY_PRODUCT_ID=producto_mensual \
--dart-define=GOOGLE_PLAY_ANNUAL_PRODUCT_ID=producto_anual
```

FCM se habilita sin guardar configuración real en Git:

```bash
--dart-define=FIREBASE_API_KEY=... \
--dart-define=FIREBASE_APP_ID=... \
--dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
--dart-define=FIREBASE_PROJECT_ID=...
```

El build sin estos parámetros conserva el modo demo y omite la inicialización
de Firebase. En producción, Crashlytics captura fallos fatales cuando
`USE_REAL_API=true`; no deben añadirse datos financieros, tokens ni documentos
como claves o logs de diagnóstico. Coloque el `google-services.json` descargado
de Firebase en `android/app/` (está excluido de Git) para que Gradle active
automáticamente los plugins Google Services y Crashlytics. Para una prueba real,
el APK/AAB debe instalarse desde Internal testing con una cuenta incluida como
license tester.

La configuración de firma y las instrucciones de distribución se encuentran en [docs/BETA_DISTRIBUTION.md](docs/BETA_DISTRIBUTION.md).

El contrato propuesto para el backend .NET 10 se encuentra en [docs/api/README.md](docs/api/README.md).

La arquitectura, las migraciones PostgreSQL y el desarrollo por etapas se encuentran en [docs/backend/README.md](docs/backend/README.md).

## Configuración segura

El repositorio no debe contener credenciales reales. Para firmar Android, copiá
`android/key.properties.example` como `android/key.properties` y completalo solo
en tu entorno local. Los keystores, archivos `.env`, configuraciones Firebase,
cuentas de servicio y artefactos APK/AAB están excluidos mediante `.gitignore`.

Los códigos OTP y de recuperación incluidos en la aplicación son exclusivamente
datos mock para la prueba piloto. No deben reutilizarse al conectar el backend.
