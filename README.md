# Finanza

Aplicación Flutter para la gestión de finanzas personales y familiares. Su
identidad visual usa una paleta clara verde, el isotipo de hoja y la navegación
Inicio · Movimientos · Añadir · Análisis · Más. Puede
ejecutarse con repositorios mock para demostraciones aisladas o conectada a la
API ASP.NET Core mediante parámetros de compilación.

## Manual técnico y de operación

El manual técnico documenta la construcción de **Finanza** y permite que un
tercero pueda instalar, configurar, ejecutar, mantener y auditar el sistema. Su
versión completa se incluye en los anexos del trabajo, mientras que los
repositorios conservan las instrucciones ejecutables y la documentación que
debe mantenerse alineada con cada versión publicada.

- Repositorio de la aplicación móvil:
  [https://github.com/raquino-dev/tesis-unida](https://github.com/raquino-dev/tesis-unida)
- Repositorio del backend:
  [https://github.com/raquino-dev/tesis-unida-back](https://github.com/raquino-dev/tesis-unida-back)

El manual comprende los requisitos previos de hardware y software, con las
versiones empleadas de Flutter, Dart, Android SDK, .NET 10, PostgreSQL y Docker
Compose; el procedimiento de instalación de la aplicación, la API y el Worker;
la configuración mediante `dart-define`, variables de entorno y credenciales
externas que no se incorporan al código fuente; la arquitectura de monolito
modular y la responsabilidad de cada componente; la estructura de PostgreSQL y
las migraciones versionadas `M0001`–`M0030`; y la persistencia local mediante
SQLite cifrada, outbox y cursor de sincronización.

También documenta la seguridad aplicada mediante HTTPS/TLS, JWT, refresh tokens
rotativos, OTP, almacenamiento seguro en el dispositivo, idempotencia,
`ETag`/`If-Match`, mínimo privilegio y auditoría; la integración con Supabase,
Amazon S3, Textract, SES, Firebase Cloud Messaging y Google Play Billing; el
respaldo y restauración de PostgreSQL y de los objetos privados; los comandos de
compilación, pruebas y despliegue; y los procedimientos de monitoreo,
diagnóstico y recuperación. Ninguna contraseña, clave privada, token o
credencial de proveedor forma parte del repositorio.

### Contenido disponible en los repositorios

| Contenido | Referencia |
|---|---|
| Instalación y ejecución móvil | Secciones [Verificación local](#verificación-local) e [Integración con la API](#integración-con-la-api) |
| Configuración segura de Android, Firebase y Billing | [Configuración segura](#configuración-segura) y [Google Play Billing y Firebase](#google-play-billing-y-firebase) |
| Distribución del piloto | [docs/BETA_DISTRIBUTION.md](docs/BETA_DISTRIBUTION.md) |
| Sincronización y operación sin conexión | [docs/MODO_SIN_CONEXION.md](docs/MODO_SIN_CONEXION.md) |
| Alcance y proveedores del piloto | [docs/DECISIONES_PILOTO.md](docs/DECISIONES_PILOTO.md) y [docs/PROVEEDORES_PILOTO.md](docs/PROVEEDORES_PILOTO.md) |
| Instalación, API, Worker y migraciones | [README del backend](https://github.com/raquino-dev/tesis-unida-back#readme) |
| Arquitectura, seguridad, respaldo y operación | [Documentación técnica del backend](https://github.com/raquino-dev/tesis-unida-back/tree/main/docs/backend) |

Para reproducir el sistema se deben clonar ambos repositorios, restaurar sus
dependencias, configurar los valores del ambiente fuera de Git, aplicar las
migraciones antes de iniciar una versión que dependa de ellas, comprobar los
endpoints de salud de la API y ejecutar la aplicación con la URL HTTPS del
ambiente correspondiente. Las intervenciones operativas deben registrar fecha,
versión, responsable, impacto, resultado y acciones de seguimiento.

Las [decisiones aprobadas del piloto](docs/DECISIONES_PILOTO.md) fijan el alcance
móvil, Google Play Billing de prueba, Firebase Cloud Messaging y la prohibición
de recopilar datos del plástico de tarjetas.

## Identidad Android

- Application ID: `com.tesis.finanzasinteligentes`
- Nombre visible: `Finanza`
- Versión: `0.1.0+10`

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
--dart-define=FIREBASE_ANDROID_APP_ID=... \
--dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
--dart-define=FIREBASE_PROJECT_ID=...
```

El piloto Android incluye identificadores públicos por defecto; se pueden
reemplazar con estos parámetros o con `FIREBASE_APP_ID` como override general.
Para iOS se deben proporcionar `FIREBASE_IOS_APP_ID` y
`FIREBASE_IOS_BUNDLE_ID`, además de habilitar APNs y la capacidad Push
Notifications en Xcode. Si no existe una configuración propia para la
plataforma, Firebase no se inicializa. En producción, Crashlytics captura fallos fatales cuando
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

Los códigos OTP y de recuperación incluidos en el modo mock son exclusivamente
datos de prueba (`123456`). No deben reutilizarse al conectar el backend.
