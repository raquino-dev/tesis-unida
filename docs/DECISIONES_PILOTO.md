# Decisiones del piloto que afectan a Flutter

**Estado:** aprobado  
**Fecha:** 29 de julio de 2026

Este documento resume las decisiones que debe cumplir la aplicación Android. La
definición completa, los criterios de éxito y las tareas de proveedores se mantienen
en `tesis-unida-back/docs/DECISIONES_PILOTO.md`.

## Piloto

- diez personas adultas en Asunción;
- 28 días consecutivos;
- Android 10 o superior;
- distribución mediante Google Play Internal Testing;
- PYG como única moneda;
- datos aportados voluntariamente, sin integración bancaria;
- consentimiento, encuesta previa, métricas anonimizadas y encuesta posterior.

## Funciones obligatorias

- identidad, sesión, OTP y reautorización biométrica;
- cuentas, categorías, ingresos y gastos;
- tarjetas por alias;
- transferencias entre cuentas propias;
- movimientos recurrentes;
- presupuestos y metas;
- finanzas familiares y caja lógica;
- OCR de imágenes/PDF e importación XML SIFEN;
- revisión y corrección previa a crear movimientos;
- dashboards, reportes, PDF/XLSX y proyecciones explicables;
- indicador de salud financiera explicable y no crediticio;
- alertas internas y push mediante Firebase Cloud Messaging;
- suscripción Premium mediante Google Play Billing con license testers.

## Privacidad obligatoria de tarjetas

La aplicación puede solicitar alias, límite, saldo utilizado, cierre, vencimiento,
cuenta de pago, color y estado.

No debe mostrar, solicitar, transmitir ni persistir:

- emisor;
- últimos cuatro dígitos;
- PAN o número completo;
- nombre impreso;
- expiración;
- CVV;
- token bancario;
- credenciales o cualquier otro dato del plástico.

El alias es el identificador visible y debe ser único entre tarjetas activas del
mismo usuario. Las tarjetas sirven únicamente para planificación y seguimiento
manual.

## Integraciones móviles

### Google Play Billing

- producto mensual Premium configurado en Play Console;
- compra aprobada, rechazada y pendiente;
- renovación, cancelación y restauración;
- entrega del `purchaseToken` al backend;
- derechos Premium concedidos sólo después de la validación backend;
- ambiente de prueba sin cobros reales.

### Firebase Cloud Messaging

- permiso explícito cuando corresponda;
- registro, renovación y revocación del token;
- manejo en foreground, background y aplicación cerrada;
- navegación a la pantalla relacionada;
- preferencia para desactivar push;
- la alerta interna permanece disponible si el push no llega.

## Exclusiones móviles

- datos del plástico;
- conexiones bancarias;
- transferencias reales de dinero;
- pagos reales durante el piloto;
- score crediticio;
- iOS;
- panel web;
- multi-moneda;
- campañas publicitarias.
