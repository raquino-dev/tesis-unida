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
| CA TLS | Supabase Root 2021 CA, válida hasta el 26 de abril de 2031 |

### Uso de conexiones

- Migrador y respaldo en Lightsail: conexión directa IPv6 y TLS, después de validar
  la ruta desde la instancia; Supavisor session mode es el fallback IPv4.
- Migraciones iniciales: Supavisor session mode IPv4 con verificación completa de TLS.
- API y Worker: session pooler IPv4, con usuarios PostgreSQL distintos.
- Flutter: nunca recibe una conexión PostgreSQL ni claves Supabase.

### Acciones ligadas al despliegue o al inicio del piloto

- Configurar la copia lógica cifrada desde Lightsail hacia el bucket de respaldos.
- Validar desde Lightsail la ruta IPv6 directa del migrador y los respaldos; mantener
  Supavisor session mode como fallback IPv4.
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
| Acceso de usuarios técnicos | Sin consola y sin claves de acceso creadas |

### Pendiente antes del despliegue en AWS

- Solicitar salida del sandbox de SES para poder enviar a destinatarios no verificados.
- Generar las claves de los usuarios técnicos únicamente durante la instalación del
  servidor y almacenarlas en el archivo de entorno protegido, nunca en Git.
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
| Estado del bloque | Cerrado para desarrollo y pruebas locales |
| Cloud Messaging HTTP v1 | Habilitado |
| Cloud Messaging heredado | Inhabilitado |
| Cuenta técnica FCM | `finanzas-fcm-piloto@finanzas-piloto-ra-2026.iam.gserviceaccount.com` |
| Rol técnico | Administrador de la API de Firebase Cloud Messaging |
| Claves de la cuenta técnica | Ninguna; generar únicamente durante el despliegue |
| SHA-1 de depuración | Registrada en Firebase |
| Clave API Android | Restringida al paquete y SHA-1 de depuración |
| Configuración Android | `android/app/google-services.json`, instalada localmente y excluida de Git |
| Google Analytics | Deshabilitado durante el piloto inicial |
| Gemini en Firebase | Deshabilitado |
| Google Developer Program | No inscrito |
| Verificación Flutter | `flutter analyze`, APK debug y 38 pruebas correctas |

### Acciones ligadas al despliegue o a Play Console

- Generar una credencial de la cuenta de servicio únicamente durante el despliegue,
  almacenarla fuera de Git y validar un envío push de extremo a extremo.
- Inyectar `google-services.json` de forma segura en el pipeline de GitHub Actions.
- Registrar en Firebase la huella de la clave de firma de producción y la huella de
  Google Play App Signing cuando estén disponibles.

## Próximas altas

| Proveedor | Estado |
|---|---|
| Firebase / Google Cloud | Listo para desarrollo; pendiente validación en despliegue |
| Google Play Console | Cuenta personal creada; verificaciones obligatorias pendientes |
| GitHub Environment `pilot` | Pendiente |

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
| Categorías reguladas | Ninguna; el piloto no presta servicios financieros reales |
| Contacto administrativo | Nombre, correo y teléfono cargados; idioma `Español (Latinoamérica)` |
| Verificación de identidad y dirección | Documentos enviados; revisión de Google en curso |
| Verificación de dispositivo | Ya no aparece como tarea pendiente en el panel principal |
| Verificación de teléfono | Bloqueada hasta que Google apruebe los documentos de identidad |
| Aplicación | Bloqueada por Google hasta completar las verificaciones de cuenta |
