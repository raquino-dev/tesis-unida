# Trazabilidad de requisitos funcionales

| Requisito | Recursos principales |
|---|---|
| RF-01 Registro e inicio de sesión | `POST /usuarios`, `POST /sesiones`, `POST /sesiones/renovaciones` |
| RF-02 Recuperación y cambio de contraseña | `POST /recuperaciones-contrasena`, `POST /restablecimientos-contrasena`, `PUT /perfil/contrasena` |
| RF-03 Creación de grupos y administrador automático | `POST /grupos-familiares` |
| RF-04 Invitación, exclusión y eliminación del grupo | invitaciones, integrantes y `DELETE /grupos-familiares/{grupoId}` |
| RF-05 Ingresos/gastos privados y familiares | `/movimientos`, `/grupos-familiares/{grupoId}/movimientos` |
| RF-06 Registro manual | `POST /movimientos` |
| RF-07 Imagen/PDF con OCR | `/documentos-financieros`, `/procesamientos-documentales/{id}` |
| RF-08 XML SIFEN | `/documentos-financieros` con `tipo=xml-sifen` y procesamiento `sifen` |
| RF-09 Validación y corrección OCR/XML | `PATCH /procesamientos-documentales/{id}`, luego `POST /movimientos` |
| RF-10 Categorías predefinidas/personalizadas | `/categorias` |
| RF-11 Presupuestos privados/familiares | `/presupuestos`, `/grupos-familiares/{grupoId}/presupuestos` |
| RF-12 Metas privadas/compartidas | `/metas-ahorro`, `/metas-ahorro/{id}/aportes` |
| RF-13 Caja compartida | `/caja-compartida`, `/operaciones-caja` |
| RF-14 Dashboards/reportes individuales/familiares | `/tableros-financieros`, `/reportes-financieros` y variantes familiares |
| RF-15 Exportación PDF/Excel | `/exportaciones`, `/exportaciones/{id}/descargas` |
| RF-16 Proyecciones mensuales/por categoría | `/proyecciones-gastos` y variante familiar |
| RF-17 Alertas y recomendaciones | `/alertas-financieras` |
| RF-18 Biometría | `/credenciales-biometricas`, `/verificaciones-biometricas` |
| RF-19 OTP adaptativo | `/desafios-otp`, `/verificaciones-otp` |
| RF-20 Seguridad y auditoría | `/eventos-seguridad`, `/eventos-auditoria` |
| RF-21 Free/Premium | `/planes-suscripcion`, `/suscripcion`, `/suscripciones` |

## Cobertura adicional de módulos mock

| Módulo | Recursos |
|---|---|
| Cuentas | `/cuentas` |
| Tarjetas de crédito | `/tarjetas-credito` |
| Transferencias internas | `/transferencias` |
| Movimientos recurrentes | `/movimientos-recurrentes` |
| Score financiero | `/score-financiero` |
| Preferencias | `/perfil/preferencias` |
| Dispositivos y notificaciones | `/dispositivos` |
| Compatibilidad de cliente | `/configuracion-cliente` |

## Definition of Done por endpoint

Cada implementación debe incluir:

1. Validación de esquema y negocio.
2. Autorización por propietario/miembro/rol.
3. Pruebas unitarias y de integración.
4. Documentación OpenAPI generada por ASP.NET Core.
5. `ProblemDetails` y códigos de dominio estables.
6. Logs estructurados con `correlationId`.
7. Auditoría para operaciones críticas.
8. Idempotencia cuando corresponda.
9. Manejo transaccional o patrón outbox para efectos secundarios.
10. Métricas de latencia, errores y dependencia externa.

