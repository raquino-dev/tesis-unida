# Fase 2 · Alineación tesis ↔ aplicación móvil

Rama: `tesis/fase-2-alineacion-2026-09`

## Cambios aplicados

- El consentimiento del piloto utiliza la finalidad versionada `participacion-piloto-v2`, preservando la aceptación anterior.
- La pantalla del piloto exige la aceptación vigente remota y deja de confiar únicamente en el booleano local histórico.
- El consentimiento visible explicita 10 unidades familiares representadas por referentes adultos y 28 días de observación desde la incorporación.
- Se incorpora el instrumento `preuso-complementario`, separado del preuso basal.
- El backend define la elegibilidad del `postuso` a partir de `fecha_inicio + 28 días` y rechaza cualquier envío anticipado.
- La documentación offline se restringe al alcance Android de la tesis; iOS queda como evolución futura.
- La política de privacidad se mantiene accesible dentro de la aplicación; no se incorpora una web pública como requisito académico adicional.

## Regla metodológica

El `preuso` original sigue siendo la medición basal porque fue respondido por los diez referentes antes del primer uso. El bloque complementario solicitado por tutoría se analiza descriptivamente y no se presenta como un pretest retroactivo. Los demás adultos de cada familia pueden usar funcionalidades colaborativas, pero no pasan a formar parte automáticamente de la muestra principal `n=10`.

## Preservación y despliegue

El backend con `M0023`, `piloto.participantes`, soporte de `preuso-complementario` y control de elegibilidad del `postuso` debe desplegarse antes de distribuir el AAB que incorpora esta versión del Centro del piloto.

Como el merge a `main` despliega automáticamente contra un entorno que ya contiene datos reales, los PR no deben fusionarse hasta completar el backup y la restauración aislada definidos como primera evidencia operativa de la Fase 3.
