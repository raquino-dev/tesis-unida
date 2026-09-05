# Contratos JSON

Los campos `id`, `creadoEn`, `actualizadoEn` y `version` son generados por el servidor. Los DTO de actualización contienen únicamente campos modificables.

## Enumeraciones

| Nombre | Valores JSON |
|---|---|
| `TipoMovimiento` | `gasto`, `ingreso` |
| `TipoCuenta` | `efectivo`, `cuenta-bancaria`, `cuenta-corriente`, `cuenta-ahorro`, `tarjeta-debito`, `tarjeta-credito`, `billetera-digital`, `otra` |
| `MarcaTarjeta` | `ninguna`, `mastercard`, `visa`, `cabal`, `panal`, `american-express`, `otra` |
| `TipoCategoria` | `gasto`, `ingreso`, `ambos` |
| `PeriodoPresupuesto` | `mensual`, `trimestral`, `anual` |
| `EstadoPresupuesto` | `saludable`, `en-riesgo`, `excedido` |
| `FrecuenciaRecurrencia` | `diaria`, `semanal`, `quincenal`, `mensual`, `anual` |
| `EstadoRecurrencia` | `activo`, `pausado`, `finalizado` |
| `TipoDocumento` | `imagen`, `pdf`, `xml-sifen` |
| `EstadoProcesamiento` | `pendiente`, `procesando`, `completado`, `incompleto`, `fallido` |
| `Ambito` | `privado`, `familiar` |
| `RolFamiliar` | `propietario`, `administrador`, `integrante` |
| `EstadoInvitacion` | `pendiente`, `aceptada`, `expirada`, `revocada` |
| `TipoOperacionCaja` | `aporte`, `retiro`, `gasto-compartido` |
| `RangoReporte` | `semana`, `mes`, `trimestre`, `anio`, `personalizado` |
| `FormatoExportacion` | `pdf`, `excel` |
| `NivelAlerta` | `informacion`, `advertencia`, `error`, `exito` |
| `EstadoSuscripcion` | `gratuita`, `activa`, `vencida`, `cancelada` |
| `TipoPlan` | `gratuito`, `premium-mensual`, `premium-anual` |

## Usuarios, sesiones y seguridad

### CrearUsuarioRequest

```json
{
  "nombre": "Rodrigo Aquino",
  "correo": "rodrigo@correo.com.py",
  "contrasena": "Una-clave-segura-2026",
  "moneda": "PYG",
  "idioma": "es-PY",
  "zonaHoraria": "America/Asuncion",
  "aceptaTerminos": true
}
```

### UsuarioResponse

```json
{
  "id": "019b1234-...",
  "nombre": "Rodrigo Aquino",
  "correo": "rodrigo@correo.com.py",
  "moneda": "PYG",
  "idioma": "es-PY",
  "ubicacion": "Asuncion, Paraguay",
  "zonaHoraria": "America/Asuncion",
  "correoVerificado": false,
  "creadoEn": "2026-07-22T18:30:00Z",
  "version": 1
}
```

### CrearSesionRequest / SesionResponse

```json
{
  "correo": "rodrigo@correo.com.py",
  "contrasena": "Una-clave-segura-2026",
  "dispositivo": {
    "identificador": "android-installation-id",
    "nombre": "Pixel 8",
    "plataforma": "android",
    "versionSistema": "14",
    "versionAplicacion": "0.1.0"
  },
  "recordarDispositivo": true
}
```

```json
{
  "id": "019b-session-...",
  "accessToken": "eyJ...",
  "refreshToken": "opaque-rotating-token",
  "tipoToken": "Bearer",
  "accessTokenExpiraEn": "2026-07-22T18:45:00Z",
  "refreshTokenExpiraEn": "2026-08-21T18:30:00Z",
  "requiereOtp": false,
  "usuario": { "id": "019b1234-...", "nombre": "Rodrigo Aquino", "correo": "rodrigo@correo.com.py" }
}
```

### RenovarSesionRequest

```json
{ "refreshToken": "opaque-rotating-token", "identificadorDispositivo": "android-installation-id" }
```

### RecuperacionContrasenaRequest / RestablecimientoContrasenaRequest

```json
{ "correo": "rodrigo@correo.com.py" }
```

```json
{
  "recuperacionId": "01900000-0000-7000-8000-000000000099",
  "codigo": "123456",
  "nuevaContrasena": "Nueva-clave-2026"
}
```

### CambiarContrasenaRequest

```json
{
  "contrasenaActual": "Una-clave-segura-2026",
  "nuevaContrasena": "Nueva-clave-2026",
  "verificacionOtpId": "019b-verificacion-..."
}
```

### DesafioOtpRequest / DesafioOtpResponse / VerificacionOtpRequest

```json
{ "motivo": "cambio-contrasena", "canal": "correo" }
```

```json
{
  "id": "019b-otp-...",
  "destinoEnmascarado": "ro***@correo.com.py",
  "expiraEn": "2026-07-22T18:35:00Z",
  "intentosRestantes": 5
}
```

```json
{ "desafioId": "019b-otp-...", "codigo": "123456" }
```

La verificación exitosa devuelve:

```json
{ "id": "019b-verificacion-...", "valida": true, "expiraEn": "2026-07-22T18:40:00Z" }
```

### VerificacionBiometricaRequest

```json
{
  "identificadorDispositivo": "android-installation-id",
  "desafio": "nonce-del-servidor",
  "firma": "base64-signature",
  "clavePublicaId": "019b-key-..."
}
```

### EventoSeguridadResponse

```json
{
  "id": "019b-event-...",
  "tipo": "inicio-sesion",
  "descripcion": "Inicio de sesion desde un dispositivo habitual",
  "exitoso": true,
  "direccionIp": "2001:db8::1",
  "dispositivo": "Pixel 8",
  "ocurridoEn": "2026-07-22T18:30:00Z"
}
```

### PreferenciasResponse

```json
{
  "tema": "oscuro",
  "idioma": "es-PY",
  "moneda": "PYG",
  "zonaHoraria": "America/Asuncion",
  "notificacionesPush": true,
  "resumenSemanal": false
}
```

### CredencialBiometricaResponse

```json
{
  "id": "019b-biometric-...",
  "identificadorDispositivo": "android-installation-id",
  "nombreDispositivo": "Pixel 8",
  "algoritmo": "ES256",
  "creadaEn": "2026-07-22T18:30:00Z",
  "ultimoUsoEn": null
}
```

### EventoAuditoriaResponse

```json
{
  "id": "019b-audit-...",
  "accion": "movimiento.creado",
  "recurso": "movimiento",
  "recursoId": "019b-movement-...",
  "usuarioId": "019b-user-...",
  "grupoFamiliarId": null,
  "datosAnteriores": null,
  "datosPosteriores": { "monto": 285000, "tipo": "gasto" },
  "correlationId": "019b-correlation-...",
  "ocurridoEn": "2026-07-22T18:30:00Z"
}
```

## Cuentas, categorías y tarjetas

### CuentaRequest / CuentaResponse

```json
{
  "nombre": "Caja de ahorro",
  "tipo": "cuenta-ahorro",
  "marca": "ninguna",
  "saldoInicial": 25000000,
  "activa": true
}
```

```json
{
  "id": "019b-account-...",
  "nombre": "Caja de ahorro",
  "tipo": "cuenta-ahorro",
  "marca": "ninguna",
  "saldoInicial": 25000000,
  "saldoActual": 26340000,
  "activa": true,
  "enUso": true,
  "version": 3
}
```

### CategoriaRequest / CategoriaResponse

```json
{ "nombre": "Alimentacion", "tipo": "gasto", "icono": "restaurant", "color": "#6868A6" }
```

```json
{
  "id": "019b-category-...",
  "nombre": "Alimentacion",
  "tipo": "gasto",
  "icono": "restaurant",
  "color": "#6868A6",
  "predefinida": false,
  "enUso": true,
  "version": 1
}
```

### TarjetaCreditoRequest / TarjetaCreditoResponse

```json
{
  "alias": "Itaú Mastercard",
  "cuentaId": "019b-account-...",
  "diaCierre": 20,
  "diaVencimiento": 5,
  "limiteTotal": 15000000
}
```

```json
{
  "id": "019b-card-...",
  "alias": "Itaú Mastercard",
  "cuenta": { "id": "019b-account-...", "nombre": "Credito", "tipo": "tarjeta-credito" },
  "diaCierre": 20,
  "diaVencimiento": 5,
  "fechaCierreExcepcional": null,
  "limiteTotal": 15000000,
  "limiteUtilizado": 4200000,
  "limiteDisponible": 10800000,
  "version": 1
}
```

## Movimientos y documentos

### MovimientoRequest

```json
{
  "ambito": "privado",
  "tipo": "gasto",
  "monto": 285000,
  "fecha": "2026-07-22T15:30:00Z",
  "categoriaIds": ["019b-category-..."],
  "descripcion": "Supermercado",
  "cuentaId": "019b-account-...",
  "documentoId": "019b-document-...",
  "movimientoRecurrenteId": null
}
```

Para ámbito familiar se agrega `grupoFamiliarId`; la cuenta debe estar compartida.

### MovimientoResponse

```json
{
  "id": "019b-movement-...",
  "ambito": "privado",
  "tipo": "gasto",
  "monto": 285000,
  "fecha": "2026-07-22T15:30:00Z",
  "categorias": [{ "id": "019b-category-...", "nombre": "Alimentacion", "color": "#6868A6" }],
  "descripcion": "Supermercado",
  "cuenta": { "id": "019b-account-...", "nombre": "Debito", "tipo": "tarjeta-debito" },
  "documento": {
    "id": "019b-document-...",
    "tipo": "imagen",
    "estadoProcesamiento": "completado"
  },
  "creadoPor": { "id": "019b-user-...", "nombre": "Rodrigo Aquino" },
  "creadoEn": "2026-07-22T18:30:00Z",
  "version": 1
}
```

### DocumentoFinancieroResponse

La carga utiliza `multipart/form-data` con partes `archivo`, `tipo`, `ambito` y `grupoFamiliarId` opcional.

```json
{
  "id": "019b-document-...",
  "nombreOriginal": "factura.pdf",
  "tipo": "pdf",
  "mimeType": "application/pdf",
  "tamanoBytes": 248120,
  "sha256": "hex-sha256",
  "estadoProcesamiento": "pendiente",
  "procesamientoId": "019b-process-...",
  "creadoEn": "2026-07-22T18:30:00Z"
}
```

### ProcesamientoDocumentalResponse

```json
{
  "id": "019b-process-...",
  "documentoId": "019b-document-...",
  "tipo": "ocr",
  "estado": "incompleto",
  "confianza": 0.72,
  "datosDetectados": {
    "monto": 285000,
    "fecha": "2026-07-22",
    "comercio": "Supermercado San Roque",
    "categoriaSugeridaId": "019b-category-...",
    "cdcSifen": null
  },
  "advertencias": ["La fecha posee baja confianza"],
  "iniciadoEn": "2026-07-22T18:30:01Z",
  "finalizadoEn": "2026-07-22T18:30:04Z"
}
```

XML SIFEN utiliza `tipo: "sifen"` y completa `cdcSifen`, timbrado, RUC, número de comprobante e impuestos cuando estén disponibles.

### MovimientoRecurrenteRequest

```json
{
  "tipo": "gasto",
  "monto": 180000,
  "categoriaIds": ["019b-category-..."],
  "cuentaId": "019b-account-...",
  "descripcion": "Internet",
  "fechaInicio": "2026-07-01",
  "fechaFin": null,
  "frecuencia": "mensual",
  "cantidadOcurrencias": null
}
```

Respuesta agrega `id`, `ocurrenciasCompletadas`, `proximaEjecucion`, `estado` y `version`.

```json
{
  "id": "019b-recurring-...",
  "tipo": "gasto",
  "monto": 180000,
  "categorias": [{ "id": "019b-category-...", "nombre": "Servicios" }],
  "cuenta": { "id": "019b-account-...", "nombre": "Debito" },
  "descripcion": "Internet",
  "fechaInicio": "2026-07-01",
  "fechaFin": null,
  "frecuencia": "mensual",
  "cantidadOcurrencias": null,
  "ocurrenciasCompletadas": 1,
  "proximaEjecucion": "2026-08-01",
  "estado": "activo",
  "version": 2
}
```

### TransferenciaRequest / TransferenciaResponse

```json
{ "cuentaOrigenId": "019b-a1", "cuentaDestinoId": "019b-a2", "monto": 500000, "fecha": "2026-07-22T18:30:00Z", "nota": "Ahorro mensual" }
```

```json
{
  "id": "019b-transfer-...",
  "cuentaOrigen": { "id": "019b-a1", "nombre": "Efectivo" },
  "cuentaDestino": { "id": "019b-a2", "nombre": "Caja de ahorro" },
  "monto": 500000,
  "fecha": "2026-07-22T18:30:00Z",
  "nota": "Ahorro mensual",
  "creadoEn": "2026-07-22T18:30:01Z"
}
```

## Presupuestos y metas

### PresupuestoRequest / PresupuestoResponse

```json
{
  "ambito": "privado",
  "grupoFamiliarId": null,
  "nombre": "Alimentacion mensual",
  "monto": 3500000,
  "periodo": "mensual",
  "categoriaIds": ["019b-category-..."]
}
```

```json
{
  "id": "019b-budget-...",
  "ambito": "privado",
  "nombre": "Alimentacion mensual",
  "monto": 3500000,
  "gastado": 1920000,
  "disponible": 1580000,
  "progreso": 0.5486,
  "estado": "saludable",
  "periodo": "mensual",
  "categorias": [{ "id": "019b-category-...", "nombre": "Alimentacion" }],
  "version": 1
}
```

### MetaAhorroRequest / MetaAhorroResponse

```json
{
  "ambito": "familiar",
  "grupoFamiliarId": "019b-family-...",
  "nombre": "Vacaciones familiares",
  "montoObjetivo": 9000000,
  "fechaObjetivo": "2027-01-15"
}
```

```json
{
  "id": "019b-goal-...",
  "ambito": "familiar",
  "grupoFamiliarId": "019b-family-...",
  "nombre": "Vacaciones familiares",
  "montoObjetivo": 9000000,
  "montoAhorrado": 2250000,
  "montoRestante": 6750000,
  "progreso": 0.25,
  "fechaObjetivo": "2027-01-15",
  "version": 2
}
```

### AporteMetaRequest / AporteMetaResponse

```json
{ "monto": 250000, "cuentaOrigenId": "019b-account-...", "nota": "Aporte de julio" }
```

```json
{
  "id": "019b-contribution-...",
  "metaAhorroId": "019b-goal-...",
  "monto": 250000,
  "aportadoPor": { "id": "019b-user-...", "nombre": "Rodrigo Aquino" },
  "fecha": "2026-07-22T18:30:00Z",
  "saldoMeta": 2500000
}
```

## Familia y caja compartida

### GrupoFamiliarRequest / GrupoFamiliarResponse

```json
{ "nombre": "Familia Aquino" }
```

```json
{
  "id": "019b-family-...",
  "nombre": "Familia Aquino",
  "miRol": "propietario",
  "cantidadIntegrantes": 3,
  "cantidadCuentasCompartidas": 2,
  "creadoEn": "2026-07-22T18:30:00Z",
  "version": 1
}
```

### InvitacionFamiliarRequest / InvitacionFamiliarResponse

Se debe enviar `correo` o `identificadorUsuario`.

```json
{ "correo": "familiar@correo.com", "identificadorUsuario": null, "rol": "integrante" }
```

```json
{
  "id": "019b-invite-...",
  "grupoFamiliarId": "019b-family-...",
  "correo": "familiar@correo.com",
  "codigo": "482915",
  "estado": "pendiente",
  "expiraEn": "2026-07-29T18:30:00Z"
}
```

### AceptacionInvitacionRequest

```json
{ "codigo": "482915" }
```

### IntegranteFamiliarResponse

```json
{ "id": "019b-user-...", "nombre": "Maria Aquino", "correo": "maria@correo.com", "rol": "integrante", "incorporadoEn": "2026-07-22T18:30:00Z" }
```

### OperacionCajaRequest / OperacionCajaResponse

```json
{
  "tipo": "aporte",
  "monto": 1000000,
  "descripcion": "Aporte mensual",
  "cuentaPrivadaId": "019b-account-...",
  "movimientoFamiliarId": null,
  "verificacionOtpId": null
}
```

Retiros y gastos requieren OTP y rol administrativo.

```json
{
  "id": "019b-treasury-...",
  "tipo": "aporte",
  "monto": 1000000,
  "descripcion": "Aporte mensual",
  "realizadoPor": { "id": "019b-user-...", "nombre": "Rodrigo Aquino" },
  "fecha": "2026-07-22T18:30:00Z",
  "saldoAnterior": 2500000,
  "saldoPosterior": 3500000
}
```

### CajaCompartidaResponse

```json
{ "grupoFamiliarId": "019b-family-...", "saldo": 3500000, "totalAportesMes": 2000000, "totalRetirosMes": 500000, "version": 8 }
```

## Analítica

### DashboardResponse

```json
{
  "ambito": "privado",
  "periodo": { "desde": "2026-07-01", "hasta": "2026-07-31" },
  "ingresos": 7900000,
  "gastos": 1383000,
  "balance": 6517000,
  "presupuestoTotal": 40500000,
  "presupuestoDisponible": 39117000,
  "scoreFinanciero": 78,
  "categoriasPrincipales": [{ "categoriaId": "019b-category-...", "nombre": "Alimentacion", "monto": 327000, "porcentaje": 0.2364 }],
  "proximosRecurrentes": [{ "nombre": "Internet", "monto": 180000, "fecha": "2026-08-01" }],
  "alertasDestacadas": ["Tu presupuesto de alimentación está cerca del límite"]
}
```

### ReporteResponse

```json
{
  "ambito": "privado",
  "rango": "mes",
  "desde": "2026-07-01",
  "hasta": "2026-07-31",
  "ingresos": 7900000,
  "gastos": 1383000,
  "balance": 6517000,
  "distribucion": [{ "categoriaId": "019b-category-...", "nombre": "Alimentacion", "monto": 327000, "porcentaje": 0.2364 }],
  "tendencia": [{ "periodo": "2026-07", "ingresos": 7900000, "gastos": 1383000 }],
  "observaciones": ["Alimentación es la categoría con mayor gasto"]
}
```

### ExportacionRequest / ExportacionResponse

```json
{
  "formato": "pdf",
  "ambito": "privado",
  "grupoFamiliarId": null,
  "desde": "2026-07-01",
  "hasta": "2026-07-31",
  "filtros": { "tipo": "gasto", "categoriaId": null, "cuentaId": null, "documento": "cualquiera" }
}
```

```json
{
  "id": "019b-export-...",
  "formato": "pdf",
  "estado": "completado",
  "creadoEn": "2026-07-22T18:30:00Z",
  "finalizadoEn": "2026-07-22T18:30:02Z",
  "cantidadMovimientos": 18,
  "totales": { "ingresos": 7900000, "gastos": 1383000, "transferido": 500000 },
  "descarga": { "url": "https://s3...signed", "expiraEn": "2026-07-22T18:40:00Z" }
}
```

### ProyeccionResponse

```json
{
  "ambito": "privado",
  "mesesHistorial": 2,
  "preliminar": true,
  "gastoProyectado": 3850000,
  "balanceProyectado": 4050000,
  "categoriaMayorCrecimiento": "Transporte",
  "nivelRiesgo": "bajo",
  "categorias": [{ "nombre": "Transporte", "montoProyectado": 620000, "variacion": 0.28 }],
  "historial": [{ "periodo": "2026-06", "proyectado": 3600000, "real": 3550000 }],
  "generadoEn": "2026-07-22T18:30:00Z"
}
```

### AlertaResponse

```json
{
  "id": "019b-alert-...",
  "titulo": "Gasto en transporte por encima del promedio",
  "mensaje": "Transporte representa 18% de tus gastos registrados.",
  "nivel": "advertencia",
  "fecha": "2026-07-22T18:30:00Z",
  "queOcurrio": "El gasto supera el promedio reciente.",
  "datosUtilizados": "Movimientos de los últimos 90 días.",
  "impacto": "El presupuesto podría agotarse antes de fin de mes.",
  "recomendacion": "Revisá los traslados recientes.",
  "leida": false
}
```

### ScoreResponse

```json
{
  "score": 78,
  "estado": "equilibrado",
  "factoresPositivos": ["Balance mensual positivo"],
  "factoresNegativos": ["Aumento en gastos variables"],
  "historial": [{ "periodo": "2026-06", "score": 76 }],
  "recomendaciones": ["Mantené un fondo de emergencia"]
}
```

## Suscripciones

### PlanSuscripcionResponse

```json
{
  "id": "premium-mensual",
  "nombre": "Premium mensual",
  "precio": 45000,
  "moneda": "PYG",
  "periodo": "mensual",
  "capacidades": ["ocr", "predicciones", "exportaciones", "alertas-prioritarias"],
  "destacado": true
}
```

### SuscripcionRequest / SuscripcionResponse

```json
{ "planId": "premium-mensual", "proveedor": "google-play", "comprobante": "purchase-token", "verificacionOtpId": "019b-verificacion-..." }
```

```json
{
  "id": "019b-subscription-...",
  "estado": "activa",
  "plan": { "id": "premium-mensual", "nombre": "Premium mensual" },
  "iniciadaEn": "2026-07-22T18:30:00Z",
  "renovacionEn": "2026-08-22T18:30:00Z",
  "capacidades": ["ocr", "predicciones", "exportaciones", "alertas-prioritarias"]
}
```

## Cliente y dispositivos

### DispositivoRequest / DispositivoResponse

```json
{
  "identificadorInstalacion": "android-installation-id",
  "nombre": "Pixel 8",
  "plataforma": "android",
  "versionSistema": "14",
  "versionAplicacion": "0.1.0",
  "tokenPush": "fcm-token",
  "zonaHoraria": "America/Asuncion"
}
```

```json
{
  "id": "019b-device-...",
  "identificadorInstalacion": "android-installation-id",
  "nombre": "Pixel 8",
  "plataforma": "android",
  "versionAplicacion": "0.1.0",
  "confiable": true,
  "ultimoAccesoEn": "2026-07-22T18:30:00Z",
  "version": 1
}
```
