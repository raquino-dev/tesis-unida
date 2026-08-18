# Modo sin conexión

## Alcance implementado

La aplicación conserva lectura y escritura sin internet para información personal:

- cuentas;
- categorías;
- movimientos manuales;
- presupuestos;
- metas de ahorro privadas y sus aportes;
- movimientos recurrentes;
- tarjetas representadas únicamente por alias;
- consentimiento informado y respuestas de los instrumentos del piloto.

El tablero y los reportes se recalculan con los movimientos disponibles en el dispositivo. Los últimos valores del score, presupuesto y alertas se muestran solo cuando exista una copia previa válida.

Por consistencia o por depender de proveedores externos, requieren conexión:

- Google Play Billing y restauración de compras;
- OCR, carga y descarga de comprobantes;
- notificaciones push;
- colaboración y finanzas familiares;
- transferencias entre cuentas (operación atómica);
- exportaciones.

## Arquitectura

`ApiClient` actúa como punto único de red. Una lectura exitosa autenticada guarda su respuesta. Ante una pérdida real de red o una respuesta transitoria 408, 429, 502, 503 o 504:

1. una lectura devuelve la copia local y marca `x-offline-cache`;
2. una escritura admitida crea una operación en el outbox y devuelve una respuesta optimista con `x-offline-pending`;
3. la interfaz sigue trabajando con el identificador UUID definitivo generado por el cliente.

La base local SQLite se guarda en Application Support y se cifra mediante `sqlite3mc`. La clave aleatoria de 256 bits vive en `FlutterSecureStorage`, separada del archivo. Cada fila está particionada por un hash del `sub` del JWT; al cerrar sesión se elimina la caché y el outbox de ese usuario.

La sesión offline dura como máximo siete días desde la última autenticación online. La biometría configurada continúa protegiendo la apertura local.

## Sincronización

El outbox se procesa secuencialmente en el orden de creación. Cada alta lleva un UUID definitivo y cada operación una `Idempotency-Key`. Las operaciones usan `If-Match` para no sobrescribir versiones modificadas en otro dispositivo.

La sincronización se activa:

- al recuperar conectividad;
- al volver la aplicación al primer plano;
- antes de una lectura online;
- manualmente al tocar la barra de estado;
- en segundo plano cada 15 minutos en Android, cuando el sistema dispone de red;
- mediante Background Fetch en iOS, con frecuencia decidida por iOS.

El destino mínimo de iOS es 15.0 porque las versiones instaladas de Firebase Core, Messaging y Crashlytics lo requieren.

Después del push se consulta `GET /sincronizacion` con un cursor. El backend devuelve cambios y tombstones; el cliente refresca solamente las colecciones afectadas. El cursor se guarda por usuario.

Los fallos transitorios usan backoff exponencial hasta cinco intentos. Después quedan visibles como fallidos y pueden reintentarse manualmente. Un 409 o 412 se presenta como conflicto y nunca se sobrescribe automáticamente: el usuario puede descartar el cambio local para conservar el servidor.

## Orden de despliegue

1. Desplegar primero `tesis-unida-back` desde `main`. El migrador aplica `M0022_SincronizacionOffline` y crea `sincronizacion.cambios`.
2. Confirmar que `GET /api/v1/sincronizacion?desde=0&limite=200` responde 200 con un JWT válido.
3. Generar el siguiente AAB de Flutter y publicarlo en prueba interna.
4. No distribuir el AAB offline antes de desplegar el endpoint del backend.

## Prueba de aceptación manual

1. Iniciar sesión con internet y abrir cuentas, categorías, movimientos, presupuestos, metas y recurrencias una vez.
2. Activar modo avión y reiniciar la app.
3. Verificar lectura, crear una categoría y una cuenta, y luego crear un movimiento que las use.
4. Editar y eliminar elementos; comprobar que la barra indica cambios pendientes.
5. Cerrar y abrir la aplicación todavía sin red; comprobar que datos y cola persisten.
6. Recuperar internet; esperar a que desaparezca el contador y verificar los datos desde otro dispositivo o Supabase.
7. Modificar el mismo registro en dos dispositivos para provocar un ETag desactualizado; verificar que se muestra como conflicto y no se sobrescribe.
8. Cerrar sesión con cambios pendientes; verificar la advertencia antes de borrar datos locales.

## Verificación automatizada

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `test/offline_store_test.dart`: aislamiento, orden, backoff y limpieza.
- `test/uuid_v4_test.dart`: UUID definitivos válidos y únicos.

Referencias técnicas: documentación oficial de [cifrado SQLite en Drift](https://drift.simonbinder.eu/platforms/encryption/) y [Workmanager](https://docs.page/fluttercommunity/flutter_workmanager/quickstart).
