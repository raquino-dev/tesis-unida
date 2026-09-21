# Distribución beta de Finanzas Inteligentes

## Identidad

- Nombre visible: `Finanzas Inteligentes`
- Identificador Android: `com.tesis.finanzasinteligentes`
- Versión actual del prototipo: `0.1.0+9`
- Los builds de prueba muestran una banda `PROTOTIPO` dentro de la aplicación.

El identificador Android debe considerarse definitivo antes de registrar la app en Google Play.

## Firma de publicación

La configuración de Gradle lee las credenciales desde `android/key.properties`. Ese archivo y los keystores están excluidos del repositorio.

1. Crear y respaldar el keystore de carga:

   ```bash
   keytool -genkeypair -v \
     -keystore finanzas-inteligentes-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias finanzas-inteligentes
   ```

2. Copiar `android/key.properties.example` como `android/key.properties`.
3. Completar la ruta absoluta, alias y contraseñas.
4. Guardar el keystore y sus contraseñas en un gestor seguro fuera del proyecto.
5. Generar el App Bundle:

   ```bash
   flutter build appbundle --release \
     --dart-define=USE_REAL_API=true \
     --dart-define=API_BASE_URL=https://api.rodrigoaquino.com/api/v1
   ```

## Recomendación para la primera prueba

Para validar diseño y usabilidad con datos ficticios, distribuir el APK mediante Firebase App Distribution. Cuando la identidad y los recorridos estén validados, utilizar el canal Internal testing de Google Play.

Los testers deben recibir estas indicaciones:

- Usar exclusivamente datos ficticios.
- La cámara, selección de archivos, biometría y almacenamiento seguro utilizan
  capacidades reales del dispositivo.
- El AAB del piloto utiliza la API real. OCR, OTP/correos, suscripciones y sesión
  dependen de los proveedores habilitados en el entorno desplegado.
- El código fijo `123456` existe únicamente en ejecuciones locales sin
  `USE_REAL_API=true`; nunca debe usarse para validar un AAB distribuible.
- El plan gratuito permite procesar hasta tres comprobantes OCR por mes.
- Completar el consentimiento y la encuesta inicial antes de probar los flujos;
  al finalizar, completar la encuesta final desde el Centro del piloto.
- Reportar problemas indicando pantalla, acción realizada y resultado esperado.
