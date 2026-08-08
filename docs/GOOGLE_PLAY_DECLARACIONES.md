# Declaraciones de Google Play

Estado aplicado en Play Console para la versión interna `0.1.0-internal.1`.

## Estado en Play Console

- 7 de 11 tareas de configuración principal completadas;
- anuncios: no contiene anuncios;
- ID de publicidad: no utilizado;
- acceso restringido: cuenta sintética de revisión registrada;
- público objetivo: mayores de 18 años;
- app gubernamental: no;
- salud: ninguna función de salud;
- funciones financieras: `Asesoramiento financiero` y `Otro`, sin necesidad de
  documentación adicional según Play Console;
- categoría: aplicación de Finanzas;
- contacto público: `rodrigoaquino.dev@gmail.com` y
  `https://rodrigoaquino.com`.

## Respuestas verificadas contra el código

| Sección | Respuesta propuesta | Fundamento |
| --- | --- | --- |
| Anuncios | No contiene anuncios | No existe SDK ni integración publicitaria. |
| App gubernamental | No | Proyecto académico privado, no desarrollado por un Gobierno ni en su nombre. |
| Salud | Ninguna función de salud | “Salud financiera” es una denominación educativa; no trata datos ni servicios médicos. |
| Funciones financieras | `Asesoramiento financiero` y `Otro` | La app analiza movimientos y presenta recomendaciones educativas personalizadas para administrar finanzas. No presta servicios regulados ni mueve dinero real. |
| Banca, préstamos y crédito | Ninguna | No presta, facilita ni administra productos financieros reales. |
| Pagos y transferencias | Ninguna | Las transferencias son asientos simulados entre cuentas registradas por el usuario. |
| Criptomonedas, inversión y seguros | Ninguna | Funciones excluidas del piloto. |
| Categoría de Play Store | Finanzas | Gestor educativo de finanzas personales y familiares. |
| Público objetivo | 18 años o más | La app está orientada a personas adultas que administran finanzas. |

## Acceso para revisión

La AAB interna se conecta al backend productivo del piloto y requiere inicio de
sesión. Para revisión y pruebas, se puede registrar una cuenta de prueba desde la
pantalla de registro usando un correo controlado por quien prueba la aplicación.
No se solicitan datos bancarios, PAN, CVV, fecha de vencimiento ni documentos
reales; las tarjetas se representan únicamente por un alias. Las transferencias y
los pagos son registros simulados dentro de la aplicación.

## Pendientes previos a completar la ficha

- publicar la política de privacidad en una URL HTTPS del dominio
  `rodrigoaquino.com`;
- publicar una página web de solicitud de eliminación de cuenta;
- completar la declaración de seguridad de datos según Firebase Messaging,
  Crashlytics, autenticación y los datos financieros gestionados;
- redactar y cargar la ficha de Play Store, icono, gráfico y capturas;
- completar el cuestionario IARC de clasificación de contenido.

## Exclusiones que deben conservarse en la descripción pública

- no es un banco, billetera ni procesadora de pagos;
- no ofrece préstamos, crédito, inversión, seguros ni criptomonedas;
- las tarjetas son alias y no almacenan PAN, CVV, fecha de vencimiento ni datos
  del plástico;
- el indicador financiero es educativo y no es un score crediticio;
- las transferencias internas no ejecutan movimientos bancarios reales.
