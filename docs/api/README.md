# API de Finanzas Inteligentes

Contrato propuesto para el backend .NET 10 que reemplazará los repositorios mock de la aplicación Flutter.

## Documentos

- [Convenciones y seguridad](CONVENCIONES.md)
- [Catálogo completo de endpoints](ENDPOINTS.md)
- [Contratos JSON y enumeraciones](CONTRATOS.md)
- [Trazabilidad con requisitos funcionales](TRAZABILIDAD_RF.md)
- [Arquitectura, migraciones y plan del backend](../backend/README.md)

## Decisiones adoptadas

| Tema | Decisión |
|---|---|
| URL base | `/api/v1` |
| Idioma | Recursos en español, sin tildes |
| Formato de rutas | Plural y `kebab-case` |
| Acciones | Se representan como recursos: `sesiones`, `aportes`, `desafios-otp`, `procesamientos-documentales` |
| JSON | `camelCase`, UTF-8 |
| Identificadores | UUID v7 como texto |
| Fechas y horas | ISO 8601 en UTC, por ejemplo `2026-07-22T18:30:00Z` |
| Fechas sin hora | `YYYY-MM-DD` |
| Zona horaria | IANA, inicialmente `America/Asuncion` |
| Importes PYG | Enteros `Int64`; PYG no utiliza decimales |
| Porcentajes | Decimal entre `0` y `1` |
| Autenticación | Bearer JWT de corta duración y refresh token rotativo |
| Errores | `application/problem+json`, compatible con `ProblemDetails` |
| Paginación | Cursor opaco con `limite` máximo 100 |
| Concurrencia | `ETag` y `If-Match` en actualizaciones sensibles |
| Idempotencia | `Idempotency-Key` en altas financieras y operaciones críticas |

## Alcance

El catálogo cubre RF-01 a RF-21 y los módulos existentes en Flutter:

- usuarios, perfil, sesiones y contraseñas;
- seguridad, OTP, biometría y auditoría;
- cuentas, tarjetas, categorías y transferencias internas;
- movimientos privados, recurrentes y documentos;
- OCR de imágenes/PDF e importación XML SIFEN;
- presupuestos y metas de ahorro;
- grupos familiares, miembros, invitaciones y caja compartida;
- dashboards, reportes, exportaciones, alertas, predicciones y score;
- planes y suscripciones.

## Decisiones pendientes del equipo

1. Proveedor final de biometría/attestation y mecanismo de vinculación de dispositivos.
2. Proveedor de pagos o si las suscripciones seguirán sólo como feature flags durante el piloto.
3. Límites máximos de archivos, retención documental y política de eliminación en S3.
4. Estructura exacta de los XML SIFEN y reglas tributarias que serán validadas.
5. Política de recálculo de presupuestos, score, alertas y predicciones.
6. Si un usuario podrá pertenecer a más de un grupo familiar en versiones futuras. Este contrato asume uno.
7. Política legal de anonimización y retención al eliminar una cuenta.
