# Plan de implementación del backend por etapas

## 1. Forma de trabajo

Cada etapa debe entregar una vertical completa:

```text
migración -> dominio -> caso de uso -> endpoint -> contrato OpenAPI
          -> pruebas de integración -> integración Flutter
```

No se considera terminada una etapa si sólo existen tablas o controladores. Los mocks Flutter se reemplazan repositorio por repositorio, manteniendo una bandera de entorno para volver temporalmente al mock durante el piloto.

Definición de terminado común:

- migraciones aplican desde una base vacía y desde la versión anterior;
- OpenAPI coincide con `docs/api`;
- respuestas y errores usan los contratos documentados;
- autorización impide leer o modificar recursos ajenos;
- altas críticas son idempotentes;
- actualizaciones sensibles validan `If-Match`;
- pruebas unitarias, integración y contrato pasan;
- logs, métricas y auditoría no exponen secretos;
- Flutter cubre estados de carga, vacío, error y reintento.

## 2. Etapa 0 — Fundación técnica

### Objetivo

Crear una solución desplegable sin desarrollar todavía funcionalidades de usuario.

### Migraciones

- `M0001_ExtensionesYEsquemas`
- `M0002_InfraestructuraProcesamiento`

### Entregables

- scaffold de API, Worker y módulos;
- PostgreSQL, Redis y S3 local mediante contenedores;
- configuración por ambiente y validación al inicio;
- ProblemDetails, correlation ID, OpenAPI y versionado `/api/v1`;
- autenticación preparada, aunque todavía sin endpoints;
- outbox, trabajos, idempotencia y reintentos;
- health checks de vida y disponibilidad;
- OpenTelemetry y logs JSON;
- pipeline de build, tests y script idempotente de migración.

### Criterios de salida

- API y Worker levantan con una base vacía;
- un evento de prueba cruza outbox y es consumido exactamente una vez desde el punto de vista funcional;
- dos instancias de Worker no reclaman simultáneamente el mismo trabajo;
- una dependencia no disponible vuelve negativo el readiness, no el liveness;
- no existen secretos dentro del repositorio.

## 3. Etapa 1 — Identidad y seguridad

### Migraciones

- `M0010_IdentidadUsuarios`
- `M0011_IdentidadSesionesYTokens`
- `M0012_SeguridadDispositivosYOtp`
- `M0013_AuditoriaEventos`

### Endpoints

- `/usuarios`, `/perfil`, `/perfil/preferencias`, `/perfil/contrasena`;
- `/sesiones`, `/sesiones/renovaciones`;
- `/recuperaciones-contrasena`, `/restablecimientos-contrasena`;
- `/desafios-otp`, `/verificaciones-otp`;
- `/credenciales-biometricas`, `/verificaciones-biometricas`;
- `/eventos-seguridad`, `/eventos-auditoria`;
- `/dispositivos`;
- `/configuracion-cliente` en su forma inicial.

### Orden interno recomendado

1. usuario, hash de contraseña y JWT;
2. sesión/refresh rotativo y revocación;
3. perfil y preferencias;
4. recuperación de contraseña;
5. dispositivo, OTP y biometría;
6. auditoría y controles de rate limit.

### Criterios de salida

- el refresh token reutilizado revoca la familia de sesión;
- recuperación no permite enumerar correos;
- OTP expira, limita intentos y sólo se consume una vez;
- un dispositivo no puede registrar credenciales para otro usuario;
- eliminar perfil inicia el flujo de anonimización acordado;
- el Flutter puede registrarse, iniciar/cerrar sesión y restaurar una sesión.

## 4. Etapa 2 — Finanzas personales esenciales

### Migraciones

- `M0020_FinanzasCategoriasYCuentas`
- `M0021_FinanzasTarjetas`
- `M0022_FinanzasMovimientos`
- `M0023_FinanzasTransferenciasYRecurrencias`

### Endpoints

- `/cuentas`;
- `/categorias`;
- `/tarjetas-credito`;
- `/movimientos`;
- `/transferencias`;
- `/movimientos-recurrentes`.

### Orden interno recomendado

1. categorías predeterminadas y personalizadas;
2. cuentas y saldos iniciales;
3. movimientos y anulación;
4. transferencias con dos movimientos;
5. tarjetas sin almacenar datos sensibles;
6. recurrencias y Worker de generación.

### Criterios de salida

- reintentar un POST con la misma clave no duplica un movimiento;
- dos gastos concurrentes no pierden actualizaciones de saldo;
- una transferencia crea exactamente dos movimientos enlazados o ninguno;
- anular revierte el saldo una sola vez y conserva historial;
- una recurrencia produce como máximo un movimiento por período;
- filtros y cursores son estables aunque se creen nuevos movimientos;
- los repositorios mock de estas pantallas pueden sustituirse por HTTP sin cambiar la UI.

Esta etapa constituye el primer MVP backend útil y es un buen punto para una beta cerrada con datos persistentes.

## 5. Etapa 3 — Colaboración familiar y caja

### Migraciones

- `M0030_FamiliaGruposEInvitaciones`
- `M0031_FamiliaCuentasYMovimientos`
- `M0032_FamiliaCaja`

### Endpoints

- `/grupos-familiares`;
- integrantes e invitaciones anidadas;
- `/invitaciones-familiares/{token}`;
- cuentas compartidas;
- movimientos familiares;
- caja compartida y operaciones.

### Orden interno recomendado

1. grupo y roles;
2. invitaciones y aceptación;
3. compartir cuentas ya existentes;
4. movimientos familiares;
5. caja, aportes y retiros con OTP.

### Criterios de salida

- sólo existe un propietario activo;
- el último propietario no puede salir sin transferencia válida;
- aceptar dos veces una invitación crea una sola membresía;
- compartir una cuenta no cambia su propietario;
- un movimiento familiar sólo usa una cuenta compartida con ese grupo;
- retiro y aporte actualizan caja/cuenta atómicamente;
- un integrante no eleva su propio rol ni consulta otro grupo.

## 6. Etapa 4 — Presupuestos y metas

### Migraciones

- `M0033_FinanzasPresupuestosYMetas`

### Endpoints

- `/presupuestos`, `/resumen-presupuestario`;
- presupuestos bajo `/grupos-familiares/{grupoId}`;
- `/metas-ahorro` y sus aportes.

### Criterios de salida

- se rechazan presupuestos solapados según la regla del producto;
- el gasto se deriva sólo de movimientos confirmados;
- el ámbito privado/familiar no puede quedar ambiguo;
- un aporte asociado a cuenta y su movimiento son atómicos;
- una meta con saldo no se elimina sin compensación;
- los límites y porcentajes funcionan correctamente con PYG entero.

## 7. Etapa 5 — Documentos, OCR, SIFEN y exportación

### Migraciones

- `M0040_DocumentosArchivosYProcesamientos`
- `M0041_DocumentosSifen`
- `M0042_DocumentosExportaciones`

### Endpoints

- `/documentos-financieros`;
- `/procesamientos-documentales`;
- recursos de descarga;
- `/exportaciones`.

### Orden interno recomendado

1. carga privada S3, metadatos y descarga prefirmada;
2. cola y estados de procesamiento;
3. adaptador OCR;
4. parser seguro de XML SIFEN;
5. corrección de datos detectados;
6. asociación con movimientos;
7. exportaciones CSV, luego XLSX y PDF.

### Criterios de salida

- se rechazan MIME/tamaños no permitidos y se verifica SHA-256;
- un usuario nunca obtiene una URL de otro usuario/grupo;
- el XML no resuelve entidades externas;
- reintentos no crean procesamientos o exportaciones duplicados;
- un proveedor caído deja el trabajo reintentable;
- archivos huérfanos y exportaciones vencidas se limpian;
- el resultado corregido conserva auditoría del original.

Hasta disponer de proveedores reales, los adaptadores OCR y correo pueden seguir siendo mocks del lado servidor; el contrato HTTP y el ciclo de estados ya deben ser reales.

## 8. Etapa 6 — Analítica

### Migraciones

- `M0050_AnaliticaAlertasYScore`
- `M0051_AnaliticaPredicciones`

### Endpoints

- `/tableros-financieros`;
- `/reportes-financieros`;
- `/proyecciones-gastos`;
- `/alertas-financieras`;
- `/score-financiero`;
- variantes familiares correspondientes.

### Orden interno recomendado

1. dashboard y reportes deterministas desde consultas;
2. caché Redis con invalidación por outbox;
3. reglas de alertas;
4. score explicable y versionado;
5. predicciones con proveedor/modelo intercambiable.

### Criterios de salida

- totales del dashboard reconcilian con movimientos;
- caché vencida nunca se vuelve fuente de verdad;
- el mismo conjunto de entrada y versión produce resultados reproducibles cuando el algoritmo lo permite;
- falta de datos devuelve `422 datos_insuficientes`;
- score y predicción identifican versión y período;
- una falla analítica no revierte un movimiento.

## 9. Etapa 7 — Suscripciones y notificaciones

### Migraciones

- `M0060_SuscripcionesPlanes`
- `M0061_NotificacionesEntregas`

### Endpoints

- `/planes-suscripcion`;
- `/suscripcion`, `/suscripciones`, `/restauraciones-suscripcion`;
- configuración/preferencias ya expuestas por perfil y dispositivos.

### Orden interno recomendado

1. planes y capacidades con proveedor interno para piloto;
2. autorización por capacidad;
3. notificaciones desde outbox;
4. proveedor real de push/correo;
5. proveedor de suscripción y validación de comprobantes, si el producto lo requiere.

### Criterios de salida

- cambiar de plan actualiza capacidades sin confiar en datos del cliente;
- recibos/eventos repetidos no duplican suscripciones;
- cancelar conserva acceso hasta la fecha acordada;
- notificaciones respetan preferencias y horario silencioso;
- fallos externos reintentan y no bloquean la operación principal.

## 10. Etapa 8 — Endurecimiento y preparación productiva

### Migraciones

- `M0070_EndurecimientoIndicesYRetencion`

### Entregables

- pruebas de carga sobre rutas financieras;
- revisión OWASP y de dependencias;
- políticas de retención, anonimización y borrado;
- índices basados en planes reales;
- backup/restauración probado;
- límites de gasto, almacenamiento y trabajos;
- runbooks de incidentes y migraciones;
- alertas operativas y objetivos de servicio;
- compatibilidad de al menos una versión anterior de la app.

### Criterios de salida

- restauración completa ensayada en un ambiente aislado;
- no hay vulnerabilidades críticas conocidas;
- una migración fallida tiene procedimiento de recuperación;
- pruebas de concurrencia crítica pasan bajo carga;
- las decisiones pendientes del contrato API están resueltas o explícitamente deshabilitadas.

## 11. Matriz de dependencias

| Capacidad | Depende de |
|---|---|
| Sesiones | Usuarios |
| OTP/biometría | Usuarios, dispositivos |
| Movimientos | Usuarios, cuentas, categorías, idempotencia |
| Transferencias | Movimientos y bloqueo de cuentas |
| Recurrencias | Movimientos, Worker y trabajos |
| Grupo familiar | Usuarios |
| Cuenta compartida | Grupo y cuenta privada |
| Caja | Grupo, cuenta, movimientos, OTP |
| Presupuesto/meta familiar | Grupo y movimientos familiares |
| OCR/SIFEN | S3, Worker, documentos |
| Dashboard/reporte | Movimientos y presupuestos |
| Alerta/score/predicción | Outbox, Worker y datos financieros |
| Suscripción | Usuarios, idempotencia, OTP opcional |
| Notificación | Outbox, preferencias y dispositivos |

## 12. Estrategia de integración con Flutter

Por cada etapa:

1. definir una interfaz de repositorio estable en Flutter;
2. conservar `Mock...Repository`;
3. añadir `Api...Repository`;
4. seleccionar implementación mediante `--dart-define` o configuración de ambiente;
5. ejecutar las mismas pruebas de comportamiento contra ambas;
6. habilitar API primero para usuarios internos;
7. eliminar el mock sólo cuando los criterios de aceptación sean estables.

La app no debe conocer nombres de tablas, proveedores o eventos internos. Sólo consume el contrato `/api/v1`, por lo que la arquitectura del backend puede evolucionar sin rehacer pantallas.

## 13. Primer bloque de trabajo recomendado

El primer incremento implementable comprende:

1. Etapa 0 completa;
2. registro, sesión y renovación de Etapa 1;
3. categorías, cuentas y movimientos de Etapa 2;
4. integración Flutter de autenticación y movimientos;
5. pruebas de idempotencia, aislamiento por usuario y saldo concurrente.

Ese bloque valida la arquitectura con el flujo más importante antes de invertir en OCR, analítica o proveedores externos.

