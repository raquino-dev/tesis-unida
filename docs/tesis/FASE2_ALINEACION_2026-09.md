# Fase 2 · Alineación tesis ↔ aplicación móvil

Rama: `tesis/fase-2-alineacion-2026-09`

## Cambios aplicados

- El consentimiento del piloto utiliza la finalidad versionada `participacion-piloto-v2`, preservando la aceptación anterior.
- La pantalla del piloto exige la aceptación vigente remota y deja de confiar únicamente en el booleano local histórico.
- El consentimiento visible explicita 10 unidades familiares representadas por referentes adultos y 28 días de observación desde la incorporación.
- Se incorpora el instrumento `preuso-complementario`, separado del preuso basal.
- La documentación offline se restringe al alcance Android de la tesis; iOS queda como evolución futura.

## Regla metodológica

El `preuso` original sigue siendo la medición basal porque fue respondido por los diez referentes antes del primer uso. El bloque complementario solicitado por tutoría se analiza descriptivamente y no se presenta como un pretest retroactivo.

## Preservación y despliegue

El backend con `M0023` y soporte de `preuso-complementario` debe desplegarse antes de distribuir el AAB que incorpora esta versión del Centro del piloto.
