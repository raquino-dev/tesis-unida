# Evaluación OCR del piloto

## Objetivo

Validar el flujo privado **Flutter → API → S3 → Worker/Textract → API** con entre
30 y 50 comprobantes autorizados y anonimizados. La evaluación mide la extracción
automática previa a cualquier corrección del usuario: **total**, **fecha** y
**comercio**.

## Protección de datos

- No subir documentos de participantes sin consentimiento expreso.
- Antes de la carga, ocultar o reemplazar nombre, RUC/CI, dirección, teléfono,
  correo, número de tarjeta, código de barras/QR y cualquier identificador de pago.
- Usar solamente una copia anonimizada por comprobante. Los originales no salen del
  dispositivo de quien realiza la prueba.
- No adjuntar imágenes/PDF, URLs prefirmadas, respuestas completas de Textract ni
  datos personales a Git, issues, capturas públicas o la tesis.
- Usar IDs correlativos (`OCR-001` a `OCR-050`) y conservar la tabla de valores
  esperados en almacenamiento privado.
- Al terminar la evaluación, borrar los documentos de prueba desde la app (y
  verificar que no queden en S3) salvo que una política documentada requiera una
  retención mayor.

## Diseño de la muestra

Meta: 40 comprobantes; mínimo aceptable: 30; máximo: 50.

| Grupo | Meta | Formatos sugeridos |
|---|---:|---|
| Ticket térmico legible | 15 | foto JPG/PNG |
| Factura o recibo impreso | 10 | foto JPG/PNG o PDF |
| Captura/recibo digital | 10 | JPG/PNG o PDF |
| Casos difíciles | 5 | iluminación baja, inclinación moderada, texto pequeño o varios totales |

No se debe alterar el monto, la fecha ni el nombre comercial durante la
anonimización. Si es imprescindible ocultar el comercio, no usar ese caso para la
métrica de comercio y dejar el motivo consignado en la matriz.

## Procedimiento por comprobante

1. Asignar el ID `OCR-###` y anotar el valor esperado antes de subir el archivo.
2. Abrir en la app el flujo de OCR y seleccionar el archivo anonimizado.
3. Esperar el estado final. Registrar el resultado automático, la confianza,
   advertencias y el tiempo aproximado de respuesta.
4. Comparar valores detectados contra los esperados **sin corregirlos aún**.
5. Si es necesario, aplicar una corrección solamente para confirmar que el recorrido
   posterior permite crear el movimiento. Marcar la fila como `corregido`.
6. Registrar un único resultado por comprobante en la matriz. Si falla el sistema,
   no reintentar más de una vez antes de registrar el fallo y revisar logs.
7. Al finalizar, eliminar el documento desde la app y marcar la eliminación.

## Criterios de comparación

- **Total correcto:** coincidencia exacta en guaraníes. Si se decide admitir una
  tolerancia, documentarla antes de medir (recomendación: `0 PYG`).
- **Fecha correcta:** mismo día ISO (`AAAA-MM-DD`).
- **Comercio correcto:** coincidencia normalizada sin distinguir mayúsculas,
  espacios repetidos, acentos ni razón social abreviada previamente definida.
- Los estados fallido, incompleto o sin valor detectado cuentan como incorrectos
  para ese campo, pero se conservan para analizar la causa.

## Indicadores a reportar

Para cada campo, calcular:

`precisión = comprobantes correctos / comprobantes evaluables × 100`

También reportar tasa de procesamiento completado, número de correcciones manuales,
latencia mediana y distribución de causas de error. Separar resultados por tipo de
documento; no mezclar casos sin comercio visible en el denominador de comercio.

## Evidencia

Usar [plantilla_evaluacion_ocr_piloto.csv](plantilla_evaluacion_ocr_piloto.csv) en
una carpeta privada. Guardar en Git solo esta plantilla vacía y el resumen agregado
sin datos personales ni imágenes.
