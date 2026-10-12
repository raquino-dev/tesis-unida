# Expediente de evidencias Finanza — 2026-10-05

Ejecución nueva sobre el árbol de trabajo actual, con cambios locales. No sustituye los resultados históricos del 8 de septiembre. No se modificó código ni se realizaron commits.

## Resultados

- Flutter: 95 pruebas aprobadas, 1 fallida (RF-15: binding no inicializado al cargar la fuente del PDF).
- flutter analyze: sin incidencias.
- Backend: compilación sin errores ni advertencias; 109 aprobadas y 1 omitida por dependencia de PostgreSQL.
- Arquitectura: 3 pruebas aprobadas (incluidas en el total backend).
- Offline/piloto: 7 pruebas aprobadas (almacenamiento en memoria; incluidas en el total Flutter).
- API desplegada: /salud/listo HTTP 200 Healthy. Las rutas /health y /health/ready devolvieron 404; la ruta válida se obtuvo del código.
- App Android iniciada en Medium_Phone_API_36.1 en modo mock. También se abrió la app web mock.

## Índice por evidencia

|ID|Resultado obtenido|Fuente|
|---|---|---|
|EVID-CP-01|Resultado actual: 95 aprobadas y 1 fallida. La cifra histórica de 58 no se reproduce en esta ejecución.|[Ficha](fichas/EVID-CP-01.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-02|Compilación: 0 errores / 0 advertencias. Pruebas: 109 aprobadas, 1 omitida; la omitida requiere PostgreSQL.|[Ficha](fichas/EVID-CP-02.html), [fuente](logs/dotnet-test.txt)|
|EVID-CP-03|Prueba automatizada mock aprobada. Capturas del formulario y del consentimiento disponibles. Aceptación manual del piloto pendiente de autorización.|[Ficha](fichas/EVID-CP-03.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-04|Pruebas automatizadas mock de movimientos y categorías aprobadas. Falta captura de alta conectada real.|[Ficha](fichas/EVID-CP-04.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-05|Pruebas automatizadas mock aprobadas. No acredita creación conectada en producción.|[Ficha](fichas/EVID-CP-05.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-06|El registro maestro dice solamente escenario funcional documentado. La tabla de casos define CP-06 como XML SIFEN: esta prueba mock aprobó. Debe confirmarse el alcance del ID.|[Ficha](fichas/EVID-CP-06.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-07|Pruebas mock de OCR y corrección aprobadas. No acredita 378 comprobantes, 92,59 % ni 3 segundos: esos resultados requieren el dataset y registro histórico.|[Ficha](fichas/EVID-CP-07.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-08|Pruebas mock de reportes y Free/Premium aprobadas. Exportación RF-15 falló por binding Flutter no inicializado al cargar fuentes PDF.|[Ficha](fichas/EVID-CP-08.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-09|Pruebas mock de recuperación y OTP aprobadas; captura OTP demo disponible. Falta demostrar envío y recepción real SES.|[Ficha](fichas/EVID-CP-09.html), [fuente](logs/flutter-test.txt)|
|EVID-CP-10|3 pruebas de arquitectura aprobadas. Verifican dependencias del Dominio, ausencia de EF en endpoints y composición de Program.|[Ficha](fichas/EVID-CP-10.html), [fuente](logs/dotnet-test.txt)|
|EVID-CP-11|Se conserva matriz actual del repositorio (RF-01–RF-21 más módulos). La tesis habla de RF-01–RF-26: pendiente conciliar numeración antes de afirmar cierre.|[Ficha](fichas/EVID-CP-11.html), [fuente](logs/TRAZABILIDAD_RF.md)|
|EVID-CP-12|flutter analyze: sin incidencias.|[Ficha](fichas/EVID-CP-12.html), [fuente](logs/flutter-analyze.txt)|
|EVID-CP-13|7 pruebas de almacenamiento en memoria y preparación piloto aprobadas. No acreditan sincronización multidispositivo ni conflicto con servidor.|[Ficha](fichas/EVID-CP-13.html), [fuente](logs/offline-test.txt)|
|EVID-E2E-07|GET https://api.rodrigoaquino.com/salud/listo respondió HTTP 200 Healthy. Evidencia parcial: no prueba recuperación, configuración Cloudflare ni funcionamiento de todos los proveedores.|[Ficha](fichas/EVID-E2E-07.html), [fuente](logs/api-salud-listo.txt)|

## Evidencias conectadas pendientes

- **EVID-E2E-01**: Supabase: conexión autorizada a entorno de prueba, respaldo y restauración en base aislada con log y validación posterior.
- **EVID-E2E-02**: S3: documento ficticio de prueba, cuenta/API autorizada y prueba de carga y recuperación con metadatos del objeto.
- **EVID-E2E-03**: Textract: documento ficticio, API autorizada y resultado real. Para cifras históricas: dataset de 378 documentos, comparación y tiempos.
- **EVID-E2E-04**: SES: correo de prueba autorizado, OTP recibido y registro de envío. La pantalla mock no acredita entrega.
- **EVID-E2E-05**: FCM: dispositivo con permisos, token registrado, envío real y captura de notificación recibida.
- **EVID-E2E-06**: Google Play: instalación Internal testing, cuenta license tester y compra con tarjeta de prueba; comprobante y verificación backend.
- **EVID-E2E-08**: Offline: dos sesiones/dispositivos contra API de prueba, operación sin red, reconexión, conflicto concurrente y ausencia de duplicados.

## Observaciones documentales

La tabla de casos y el registro maestro asignan distintos contenidos a varios CP (por ejemplo CP-01: registro vs pruebas Flutter; CP-02: recuperación vs backend; CP-07: OTP vs OCR). Se mantuvieron los ID del registro maestro de las capturas recibidas. CP-06 no precisa escenario. La matriz móvil contiene RF-01–RF-21 más módulos, y la tesis declara RF-01–RF-26. No se ha dado por cerrada esa conciliación.

## Capturas de interfaz

Las imágenes con sufijo demo corresponden a repositorios mock. No acreditan operaciones reales ni proveedores. Android-inicio es captura del emulador iniciado. Registro y OTP se capturaron en web local; el control OTP oculto no aceptó escritura con la herramienta de navegador. La aceptación del consentimiento queda pendiente.

## Capturas guardadas

- [EVID-CP-01-resultados.jpg](capturas/EVID-CP-01-resultados.jpg)
- [EVID-CP-02-resultados.jpg](capturas/EVID-CP-02-resultados.jpg)
- [EVID-CP-03-consentimiento-piloto-demo.jpg](capturas/EVID-CP-03-consentimiento-piloto-demo.jpg)
- [EVID-CP-03-registro-consentimiento-demo.jpg](capturas/EVID-CP-03-registro-consentimiento-demo.jpg)
- [EVID-CP-03-resultados.jpg](capturas/EVID-CP-03-resultados.jpg)
- [EVID-CP-04-resultados.jpg](capturas/EVID-CP-04-resultados.jpg)
- [EVID-CP-05-resultados.jpg](capturas/EVID-CP-05-resultados.jpg)
- [EVID-CP-06-resultados.jpg](capturas/EVID-CP-06-resultados.jpg)
- [EVID-CP-07-resultados.jpg](capturas/EVID-CP-07-resultados.jpg)
- [EVID-CP-08-resultados.jpg](capturas/EVID-CP-08-resultados.jpg)
- [EVID-CP-09-otp-demo.jpg](capturas/EVID-CP-09-otp-demo.jpg)
- [EVID-CP-09-resultados.jpg](capturas/EVID-CP-09-resultados.jpg)
- [EVID-CP-10-resultados.jpg](capturas/EVID-CP-10-resultados.jpg)
- [EVID-CP-11-resultados.jpg](capturas/EVID-CP-11-resultados.jpg)
- [EVID-CP-12-resultados.jpg](capturas/EVID-CP-12-resultados.jpg)
- [EVID-CP-13-resultados.jpg](capturas/EVID-CP-13-resultados.jpg)
- [EVID-E2E-07-health.jpg](capturas/EVID-E2E-07-health.jpg)
- [acceso-demo.jpg](capturas/acceso-demo.jpg)
- [android-inicio.png](capturas/android-inicio.png)
