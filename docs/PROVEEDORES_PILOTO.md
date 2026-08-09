# Inventario de proveedores del piloto

Actualizado: 31 de julio de 2026.

Este archivo contiene únicamente identificadores no secretos. Contraseñas, tokens,
credenciales JSON, claves IAM, certificados privados y datos de pago se almacenan fuera
de Git.

## Identidad del proyecto

| Concepto | Valor |
|---|---|
| Dominio | `rodrigoaquino.com` |
| API prevista | `api.rodrigoaquino.com` |
| Correo administrativo | `rodrigoaquino.dev@gmail.com` |
| Application ID Android | `com.tesis.finanzasinteligentes` |
| Región regional principal | `us-east-1` / North Virginia |

## Cloudflare

| Concepto | Estado |
|---|---|
| Cuenta | Creada |
| Zona `rodrigoaquino.com` | Activa |
| Plan | Free |
| SSL/TLS | Full (Strict) |
| `api.rodrigoaquino.com` | A → `107.23.27.225`, DNS-only, TTL Auto |
| DKIM de SES | 3 CNAME publicados, DNS-only, TTL Auto |
| MAIL FROM de SES | MX y SPF publicados para `bounce.rodrigoaquino.com` |
| DMARC | TXT `_dmarc` con política inicial `p=none` |

## Supabase

| Concepto | Valor |
|---|---|
| Organización | `finanzas-inteligentes-piloto` |
| Tipo | Educational |
| Plan actual | Free |
| Proyecto | `finanzas-inteligentes-piloto` |
| Project reference | `qzeipkqfmtfgrstnjtrw` |
| Región | East US (North Virginia), `us-east-1` |
| Estado | Healthy |
| Estado del bloque | Cerrado para desarrollo y pruebas |
| Data API / PostgREST | Deshabilitada |
| SSL obligatorio | Activo para todas las conexiones entrantes |
| Backup administrado | No disponible en Free; actualizar a Pro antes del piloto |
| Host directo | `db.qzeipkqfmtfgrstnjtrw.supabase.co:5432` |
| Session pooler | `aws-0-us-east-1.pooler.supabase.com:5432` |
| Roles de aplicación | `finanzas_migrador`, `finanzas_api`, `finanzas_worker` |
| Seguridad de roles | LOGIN, sin superusuario, sin crear roles/BBDD, sin bypass RLS |
| Propietario del esquema | `finanzas_migrador` mediante ejecución real de EF |
| Migraciones | M0001–M0019 aplicadas correctamente |
| Conexiones verificadas | Migrador, API y Worker mediante Supavisor session mode/TLS; API revalidada después de activar SSL obligatorio |
| Credenciales | Contraseñas independientes guardadas en el Llavero de macOS |
| CA TLS | CA oficial `prod-ca-2021.crt` instalada exclusivamente en Lightsail; conexiones con `verify-full` confirmadas |

### Uso de conexiones

- Migrador, API y Worker en Lightsail: Supavisor session mode IPv4 y TLS `verify-full`.
  El host directo no resuelve desde el plan actual; se utiliza el pooler de sesión.
- API y Worker: session pooler IPv4, con usuarios PostgreSQL distintos.
- Flutter: nunca recibe una conexión PostgreSQL ni claves Supabase.

### Acciones ligadas al despliegue o al inicio del piloto

- Configurar la copia lógica cifrada desde Lightsail hacia el bucket de respaldos.
- Mantener la CA oficial fuera de Git y renovarla únicamente si Supabase publica una nueva.
- Actualizar la organización a Pro antes de almacenar datos reales de participantes.

## AWS

| Concepto | Estado |
|---|---|
| Cuenta | Creada |
| Región operativa principal | `us-east-1` |
| MFA del usuario raíz | Activo mediante clave de paso |
| Claves de acceso del usuario raíz | Ninguna |
| Presupuesto mensual | `finanzas-inteligentes-piloto-mensual`, USD 35 |
| Alertas de presupuesto | 50% real, 80% previsto y 100% real al correo administrativo |
| Acciones automáticas de presupuesto | Ninguna |
| Identidad administrativa no raíz | Usuario IAM `rodrigo-admin`, acceso de consola |
| Grupo administrativo | `administradores`, política `AdministratorAccess` |
| Contraseña del administrador | Definitiva; almacenada fuera de Git |
| MFA de `rodrigo-admin` | Activo mediante clave de paso |
| Claves de acceso de `rodrigo-admin` | Ninguna |
| IAM Identity Center | No activado para conservar el plan y los créditos gratuitos |
| Instancia Lightsail | `finanzas-inteligentes-piloto-api`, Ubuntu 24.04 LTS |
| Plan Lightsail | General Purpose, 4 GB RAM, 2 vCPU, 80 GB SSD, USD 24/mes |
| Zona y red | `us-east-1a`, dual-stack |
| IP estática | `finanzas-inteligentes-piloto-ip` → `107.23.27.225` |
| Firewall web | HTTP/80 y HTTPS/443 para IPv4 e IPv6 |
| SSH/22 | Abierto temporalmente; restringir después de definir el despliegue automatizado |
| Acceso SSH de despliegue | Clave dedicada configurada para el servidor; no se usa la clave predeterminada de Lightsail |
| Runtime del servidor | Docker 29.1.3 y Docker Compose 2.40.3 instalados; servicio Docker habilitado |
| Utilidades de operación | Certbot, cliente PostgreSQL, `curl`, `jq` y `openssl` instalados |
| Código de backend en servidor | Repositorio clonado en `/opt/finanzas/repo`, rama `main`, revisión `470c542`; el remoto del servidor sigue exclusivamente `origin/main` |
| Acceso del servidor a GitHub | Deploy key dedicada, de solo lectura, limitada al repositorio del backend |
| Validación de backend | Suite de pruebas ejecutada correctamente en contenedor Docker |
| TLS de la API | Certificado Let's Encrypt emitido para `api.rodrigoaquino.com`; vence el 6 de noviembre de 2026 y tiene renovación automática habilitada |
| Stack de producción | Migrador completado; API y Nginx saludables, Worker en ejecución; API publicada en 80/443 mediante Nginx |
| Validación E2E de API | Cuenta sintética aislada: registro `201`, sesión `201`, perfil/cuentas/categorías `200` contra `https://api.rodrigoaquino.com/api/v1` |
| Red interna Docker | API `172.30.0.3`, Nginx `172.30.0.2`, Worker `172.30.0.4`; evita colisiones con las IP fijas del proxy |
| Protección de secretos | PFX, CA y JSON FCM montados como solo lectura para el UID del contenedor; archivos fuera de Git |
| Endurecimiento Nginx | Sistema de archivos de solo lectura; sólo conserva `CHOWN`, `SETGID` y `SETUID` para iniciar workers no privilegiados |
| Claves AWS de servicios | Creadas solo para API, Worker y respaldo; guardadas exclusivamente en archivos protegidos del servidor, fuera de Git |
| Snapshots automáticos | Deshabilitados; pendiente decidir ventana y costo de respaldo |
| Etiquetas | `project=finanzas-inteligentes`, `environment=pilot`, `component=api-worker` |
| Bucket de documentos | `finanzas-inteligentes-piloto-documentos-502704535236` |
| Seguridad de documentos | Privado, ACL deshabilitadas, bloqueo público, versionado y SSE-S3 |
| Ciclo de vida de documentos | Multipart incompletos: 7 días; versiones no actuales: 30 días |
| Bucket de respaldos | `finanzas-inteligentes-piloto-backups-502704535236` |
| Seguridad de respaldos | Privado, ACL deshabilitadas, bloqueo público, versionado y SSE-S3 |
| Ciclo de vida de respaldos | Prefijo `piloto/`: actuales 35 días; no actuales 7 días |
| Identidad SES | `rodrigoaquino.com` verificado, Easy DKIM RSA 2048 correcto |
| Remitente previsto | `no-reply@rodrigoaquino.com` |
| MAIL FROM personalizado | `bounce.rodrigoaquino.com`, verificado |
| Política IAM de API | `FinanzasPilotoApiPolicy`, acceso mínimo a documentos `piloto/*` |
| Política IAM de Worker | `FinanzasPilotoWorkerPolicy`, S3 + Textract + SES restringido al remitente |
| Política IAM de respaldo | `FinanzasPilotoBackupPolicy`, lectura/escritura en respaldos `piloto/*` |
| Usuarios técnicos | `finanzas-api-piloto`, `finanzas-worker-piloto`, `finanzas-backup-piloto` |
| Acceso de usuarios técnicos | Sin consola; claves de acceso mínimas creadas durante la instalación y custodiadas exclusivamente en el servidor |

### Pendiente operativo en AWS

- Solicitar salida del sandbox de SES para poder enviar a destinatarios no verificados.
- Restringir SSH/22 cuando quede definido el mecanismo de despliegue y recuperación.
- Decidir si se habilitan snapshots automáticos de Lightsail.

## Firebase / Google Cloud

| Concepto | Estado |
|---|---|
| Cuenta propietaria | `rodrigoaquino.dev@gmail.com` |
| Proyecto | `Finanzas Inteligentes Piloto` |
| Project ID | `finanzas-piloto-ra-2026` |
| Project number / FCM sender ID | `874909933539` |
| Plan Firebase | Spark |
| Aplicación Android | `com.tesis.finanzasinteligentes` |
| Firebase App ID | `1:874909933539:android:885f26c9a43616ab4dcad6` |
| Alias Android | `Finanzas Inteligentes Piloto Android` |
| Estado del bloque | Listo para desarrollo, pruebas locales y envío desde el Worker desplegado |
| Cloud Messaging HTTP v1 | Habilitado |
| Cloud Messaging heredado | Inhabilitado |
| Cuenta técnica FCM | `finanzas-fcm-piloto@finanzas-piloto-ra-2026.iam.gserviceaccount.com` |
| Rol técnico | Administrador de la API de Firebase Cloud Messaging |
| Claves de la cuenta técnica | Una clave JSON de despliegue custodiada exclusivamente en Lightsail; nunca se almacena en Git |
| SHA-1 de depuración | Registrada en Firebase |
| Clave API Android | Restringida al paquete y SHA-1 de depuración |
| Configuración Android | `android/app/google-services.json`, instalada localmente y excluida de Git |
| Google Analytics | Deshabilitado durante el piloto inicial |
| Gemini en Firebase | Deshabilitado |
| Google Developer Program | No inscrito |
| Verificación Flutter | `flutter analyze` sin incidencias, APK debug compilado e instalado en emulador Android; 38 pruebas correctas en la validación previa |

### Validación de clientes

- **Web:** Crashlytics queda excluido cuando `kIsWeb` es verdadero, por lo que la
  aplicación inicia correctamente. La API de producción rechaza deliberadamente el
  origen local `http://127.0.0.1:7357`: el preflight `OPTIONS` devuelve `405` y no
  expone cabeceras CORS. Esto no afecta a Android. Si el piloto incluye un cliente
  web, se deberá autorizar de forma explícita su dominio HTTPS y el método
  `OPTIONS`; no se habilitarán orígenes comodín.
- **Android:** se instalaron las Android Command-line Tools oficiales, se aceptaron
  las cinco licencias pendientes del SDK y `flutter doctor -v` quedó sin alertas.
  El AVD `Medium_Phone_API_36.1` inicia correctamente y ejecuta una compilación
  debug contra la API real mediante `USE_REAL_API=true`. El registro de una cuenta
  sintética aislada completó el recorrido hasta el consentimiento del piloto y la
  solicitud de permiso de notificaciones del sistema, ambos aceptados en el
  emulador. La cuenta llegó al Centro del piloto con las encuestas y el formulario
  de retroalimentación disponibles. El formulario también
  rechazó correctamente una contraseña sin carácter especial y contraseñas no
  coincidentes antes de enviar la solicitud.

### Hallazgos de la validación financiera

- La creación de cuentas sintéticas y su lectura posterior desde la API se
  completaron correctamente. Una transferencia con saldo de origen `0` queda
  deshabilitada en el cliente, como corresponde. Tras registrar un ingreso
  sintético, la transferencia interna de `Gs. 50.000` se persistió y apareció
  en el historial con confirmación de éxito.
- Se corrigió la serialización del color de categorías: Flutter estaba enviando
  `#AARRGGBB`, mientras que el contrato y la columna de Supabase admiten
  `#RRGGBB`. El síntoma era un `500` al crear una categoría; ahora se elimina el
  canal alfa antes de enviar la solicitud. La creación de la categoría de ingreso
  fue repetida en Android contra producción y completó correctamente.
- El flujo actual de tarjeta de crédito se validó con una tarjeta sintética:
  alias, cuenta asociada, línea total, disponible y fechas de cierre/vencimiento.
  El alcance del piloto queda cerrado sin almacenar emisor ni últimos cuatro
  dígitos; tampoco se guarda PAN, CVV ni fecha de vencimiento del plástico.
- Recurrencias: se creó y persistió desde Android un ingreso mensual sintético de
  Gs. 25.000 para `Caja piloto100000`, con la categoría `Ingreso piloto`. También
  se validaron las transiciones activa → pausada → activa desde la aplicación.

### Acciones ligadas al despliegue o a Play Console

- Validar un envío push de extremo a extremo desde Lightsail y documentar la
  rotación de la credencial.
- Registrar en Firebase la huella de la clave de firma de producción y la huella de
  Google Play App Signing cuando estén disponibles.

### Automatización de entrega desde `main`

- El flujo del backend `Deploy pilot` se activa al llegar cambios de backend a
  `main` o manualmente; en ambos casos hace checkout explícito de `main`, ejecuta
  pruebas, publica imágenes inmutables en GHCR y despliega mediante el entorno
  protegido `pilot`. Antes de iniciar Compose reconstruye en Lightsail el
  directorio `deploy/secrets` desde las copias persistentes protegidas del
  servidor (CA de Supabase, certificado de protección de datos, cuenta técnica
  de Google y certificado/clave TLS); esos archivos nunca viajan por GitHub ni
  quedan en Git. El script de despliegue se ejecuta con `sudo` no interactivo,
  limitado al usuario técnico de Lightsail, para acceder al socket Docker y a
  esos archivos protegidos. La autenticación contra GHCR también se realiza como
  `root`, que es quien ejecuta Docker Compose; las tres imágenes inmutables se
  agregan explícitamente al archivo de entorno temporal de cada despliegue. Los
  secretos montados para API y Worker se copian como `root:1654`, modo `640`:
  el grupo coincide con el usuario no privilegiado `app` de los contenedores y
  evita abrir lectura a otros usuarios del host.
- El flujo de Flutter `Build pilot Android release` se ejecuta manualmente y hace
  checkout explícito de `main`. Restaura en el runner los archivos ignorados,
  analiza, prueba y publica un AAB firmado como artefacto temporal; todavía no
  publica automáticamente en Play Console. El AAB distribuible se compila siempre
  con `USE_REAL_API=true` y `API_BASE_URL=https://api.rodrigoaquino.com/api/v1`;
  por tanto, las pruebas internas usan el backend desplegado y no los repositorios
  mock predeterminados.
- La configuración pública de Firebase usada por Flutter se versiona en
  `lib/core/config/pilot_firebase_options.dart` y toma sus valores de
  `AppEnvironment`. No contiene cuentas de servicio, llaves privadas ni
  secretos de administración; los archivos específicos de Android y las
  credenciales de firma se restauran únicamente desde secretos de GitHub.
- Secretos que deben existir en el entorno GitHub `pilot` del repositorio de
  backend: `PILOT_HOST`, `PILOT_USER`, `PILOT_SSH_PRIVATE_KEY`,
  `PILOT_SSH_KNOWN_HOSTS` y `GHCR_READ_TOKEN`. Todos están cargados. El token de
  GHCR sólo tiene `read:packages` y no vence por decisión del titular; debe
  rotarse trimestralmente y revocarse de inmediato ante cualquier sospecha de
  exposición.
- Secretos que deben existir en el entorno GitHub `pilot` del repositorio Flutter:
  `FIREBASE_ANDROID_CONFIG_BASE64`, `PLAY_UPLOAD_KEYSTORE_BASE64`,
  `PLAY_UPLOAD_KEY_ALIAS`, `PLAY_UPLOAD_KEY_PASSWORD` y
  `PLAY_UPLOAD_STORE_PASSWORD`. Los valores de archivos se almacenan codificados
  en Base64 y sólo se reconstruyen temporalmente dentro del runner. Todos están
  cargados en el entorno `pilot`. Antes de la primera publicación se recuperó
  en el Llavero del titular la contraseña del keystore de carga originalmente
  registrado en Play. Su material privado no se documenta ni se versiona; ante
  una pérdida futura debe solicitarse el restablecimiento de la clave de carga
  desde Play Console.

## Próximas altas

| Proveedor | Estado |
|---|---|
| Firebase / Google Cloud | Listo para desarrollo; pendiente validación en despliegue |
| Google Play Console | Cuenta verificada, aplicación creada y primera prueba interna activa |
| GitHub Environment `pilot` | Creado en ambos repositorios; limitado a la rama `main`; secretos de despliegue y firma cargados |

## Google Play Console

| Concepto | Estado |
|---|---|
| Cuenta propietaria | `rodrigoaquino.dev@gmail.com` |
| Tipo de cuenta | Personal / desarrollador individual |
| Nombre público del desarrollador | `Rodrigo Aquino Dev` |
| Tarifa de registro | Cuenta habilitada en Play Console; el panel ya no muestra el pago como pendiente |
| Perfil de pagos | Creado y vinculado por el titular |
| Correo público | `rodrigoaquino.dev@gmail.com`, verificado |
| Consentimiento de perfil público | Confirmado por el titular |
| Experiencia declarada | Flutter/Android, backend ASP.NET Core, PostgreSQL, FCM y Play Billing de prueba |
| Plan de publicación | 1 aplicación durante los próximos 12 meses |
| Monetización declarada | Sí, mediante suscripciones |
| Funciones financieras declaradas | `Asesoramiento financiero` y `Otro`, con alcance educativo; no presta servicios financieros regulados ni mueve dinero real |
| Contacto administrativo | Nombre, correo y teléfono cargados; idioma `Español (Latinoamérica)` |
| Verificación de identidad y dirección | Verificada por Google |
| Verificación de dispositivo | Ya no aparece como tarea pendiente en el panel principal |
| Verificación de teléfono | Completada por el titular |
| Aplicación | `Finanzas Inteligentes` creada con el paquete `com.tesis.finanzasinteligentes` |
| ID interno de Play Console | `4974144832414097501` |
| Prueba interna | Lista `Piloto interno` aplicada con 1 verificador; segmento activo y versión disponible |
| Clave de carga | RSA 4096 creada; `.jks` ignorado por Git y contraseña almacenada en el llavero de macOS |
| Primera versión interna | `0.1.0-internal.2` (`0.1.0+2`) preparada para publicación en pruebas internas |
| Enlace de participación interna | `https://play.google.com/apps/internaltest/4701655854951520496` |
| Configuración obligatoria | 7 de 11 tareas completadas: acceso de revisión, anuncios, público adulto, Gobierno, finanzas, salud y categoría/contacto |
| Categoría y contacto público | Aplicación de `Finanzas`; `rodrigoaquino.dev@gmail.com`; `https://rodrigoaquino.com` |
| ID de publicidad | Declarado como no utilizado |
| Acceso a producción | Requiere una prueba cerrada con al menos 12 verificadores durante 14 días |
