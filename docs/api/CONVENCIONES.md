# Convenciones REST, seguridad y errores

## Autorización

Todos los endpoints requieren `Authorization: Bearer <accessToken>`, excepto creación de usuario, creación/renovación de sesión, recuperación/restablecimiento de contraseña y aceptación de invitaciones mediante token.

El backend obtiene el usuario desde el JWT. No debe aceptar `usuarioId` enviado por el cliente para decidir propiedad. En recursos familiares debe validar la membresía y el rol en cada solicitud.

Roles familiares:

| Rol | Permisos principales |
|---|---|
| `propietario` | Administración total, eliminación del grupo, roles, caja y presupuestos |
| `administrador` | Invitaciones, miembros no propietarios, cuentas compartidas, caja y presupuestos |
| `integrante` | Consulta del grupo y alta de movimientos/aportes permitidos |

## Cabeceras

```http
Authorization: Bearer eyJ...
Content-Type: application/json
Accept: application/json
X-Correlation-Id: 019...
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
If-Match: "7"
```

- `X-Correlation-Id`: opcional desde el cliente; el servidor lo genera si falta.
- `Idempotency-Key`: obligatoria en creación de movimientos, transferencias, aportes/retiros, exportaciones, invitaciones, OTP y suscripciones.
- `If-Match`: obligatoria en `PATCH`, `PUT` y eliminaciones con riesgo de conflicto.
- Cada respuesta mutable devuelve `ETag`.

## Respuesta paginada

```json
{
  "datos": [],
  "paginacion": {
    "siguienteCursor": "eyJpZCI6Ii4uLiJ9",
    "hayMas": true,
    "limite": 20
  }
}
```

Parámetros comunes: `cursor`, `limite`, `orden=fecha:desc`.

## ProblemDetails

```json
{
  "type": "https://api.finanzas.example/problemas/saldo-insuficiente",
  "title": "Saldo insuficiente",
  "status": 409,
  "detail": "La caja compartida no posee saldo suficiente.",
  "instance": "/api/v1/grupos-familiares/019.../operaciones-caja",
  "codigo": "saldo_insuficiente",
  "correlationId": "019...",
  "errores": {
    "monto": ["El monto debe ser mayor que cero."]
  }
}
```

## Códigos HTTP

| Código | Uso |
|---|---|
| `200 OK` | Consulta o modificación con cuerpo |
| `201 Created` | Recurso creado; incluir `Location` |
| `202 Accepted` | OCR, exportación, correo u otro procesamiento asíncrono |
| `204 No Content` | Eliminación o modificación sin cuerpo |
| `400 Bad Request` | JSON, parámetros o formato inválido |
| `401 Unauthorized` | Token ausente, inválido o vencido |
| `403 Forbidden` | Usuario autenticado sin permiso suficiente |
| `404 Not Found` | Recurso inexistente o no visible para el usuario |
| `409 Conflict` | Duplicado, saldo insuficiente, estado incompatible o conflicto de versión |
| `412 Precondition Failed` | `ETag` desactualizado |
| `413 Content Too Large` | Archivo por encima del límite |
| `415 Unsupported Media Type` | MIME/extensión no permitida |
| `422 Unprocessable Content` | Validación de negocio |
| `429 Too Many Requests` | Rate limit, OTP o intentos de autenticación |
| `500 Internal Server Error` | Error no controlado |
| `503 Service Unavailable` | S3, SES, Redis u otra dependencia temporalmente no disponible |

## Filtros de movimientos

```text
?texto=supermercado
&tipo=gasto
&categoriaId=019...
&cuentaId=019...
&desde=2026-07-01
&hasta=2026-07-31
&documento=con-documento
&cursor=...
&limite=20
```

## Archivos

- Carga: `multipart/form-data`.
- MIME iniciales: `image/jpeg`, `image/png`, `application/pdf`, `application/xml`, `text/xml`.
- La API almacena el archivo en S3 y devuelve metadatos, nunca una ruta interna.
- La descarga utiliza una URL prefirmada de corta duración.
- El cliente debe enviar SHA-256 cuando sea posible para detectar duplicados e integridad.

## Procesos asíncronos

Los recursos con estado utilizan: `pendiente`, `procesando`, `completado`, `incompleto`, `fallido`.

Una respuesta `202` incluye `Location` y un recurso consultable:

```json
{
  "id": "019...",
  "estado": "pendiente",
  "creadoEn": "2026-07-22T18:30:00Z",
  "urlEstado": "/api/v1/procesamientos-documentales/019..."
}
```

