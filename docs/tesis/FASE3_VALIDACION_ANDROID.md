# Fase 3 · Validación Android y evidencia

## Build controlada

La build prevista para las pruebas reproducibles es `0.1.0+9`.

No debe distribuirse antes de que el backend compatible haya superado el gate de backup/restauración, prueba de M0028 y despliegue controlado.

## Entorno disponible

- 1 dispositivo Android físico.
- 1 emulador Android.
- Cuentas técnicas separadas de los participantes para escenarios destructivos o de conflicto.

## Cobertura prevista

### Consentimiento e instrumentos

- `participacion-piloto-v2` se solicita a quien conserve únicamente la aceptación histórica.
- `preuso` original permanece cerrado si ya fue respondido.
- `preuso-complementario` se presenta como bloque descriptivo solicitado por tutoría.
- `postuso` sólo puede enviarse desde la fecha individual definida por backend.
- La fecha de habilitación se basa en calendario `America/Asuncion`.
- La interfaz debe comunicar al usuario la fecha `habilitadoDesde` cuando el postuso todavía no esté disponible.

### Offline / RF-26

Con cuenta técnica:

1. iniciar con conexión y sincronizar;
2. desconectar red;
3. crear una operación privada soportada offline;
4. comprobar persistencia local/outbox;
5. recuperar conexión;
6. comprobar envío idempotente y convergencia;
7. modificar un mismo recurso desde físico y emulador para provocar conflicto controlado;
8. verificar 409/412 y política de resolución sin duplicar ni perder la operación;
9. validar tombstone en un escenario de eliminación compatible.

### FCM

- registrar token en dispositivo físico;
- enviar notificación de prueba controlada;
- conservar evidencia sanitizada de recepción;
- no exponer token completo ni contenido privado.

### Google Play Billing

Con license tester:

- producto `premium_monthly`;
- producto `premium_yearly`;
- compra de prueba;
- restauración;
- estado reflejado por backend;
- cancelación/vencimiento de prueba cuando el entorno lo permita.

No se realizan cobros reales durante el piloto académico.

## Evidencia

Cada escenario debe registrar:

- ID de evidencia;
- fecha/hora;
- build y commit;
- dispositivo/entorno sin identificadores sensibles;
- pasos;
- resultado esperado;
- resultado obtenido;
- captura/log sanitizado;
- incidencia vinculada si corresponde.

Los datos RAW permanecen fuera de Git.
