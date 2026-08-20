# Modelo Supertonic 3

Modelo de síntesis de texto a voz (TTS) usado en la aplicación.

## Resumen

Supertonic 3 es un modelo TTS que genera audio de alta calidad a partir de texto, con voces condicionadas por estilo. Se ejecuta on-device vía ONNX Runtime — sin nube ni GPU.

- **Repo oficial**: [Supertone/supertonic-3 en Hugging Face](https://huggingface.co/Supertone/supertonic-3)
- **Licencia**: OpenRAWL-M (créditos en la sección Acerca de de la app)

## Especificaciones

| Propiedad | Valor |
|-----------|-------|
| Tamaño total | ~400 MB (15 archivos) |
| Formato | ONNX |
| Salida de audio | Float32 PCM |
| Frecuencia de muestreo | 44100 Hz |
| Canales | Mono |
| Pasos de inferencia | 5–12 (más = mejor calidad) |

## Archivos del Modelo

Descargados a `<app_support>/modelo/` por `ModeloManager` (`features/modelo/data/repositories/modelo_manager.dart`):

| Archivo | Tamaño | Verificación |
|---------|--------|--------------|
| `onnx/duration_predictor.onnx` | ~3.7 MB | SHA-256 |
| `onnx/text_encoder.onnx` | ~36.4 MB | SHA-256 |
| `onnx/vector_estimator.onnx` | ~256.5 MB | SHA-256 |
| `onnx/vocoder.onnx` | ~101.4 MB | SHA-256 |
| `onnx/tts.json` | ~8 KB | Tamaño + parseo |
| `onnx/unicode_indexer.json` | ~278 KB | Tamaño + parseo |
| `voice_styles/F1–F5.json`, `M1–M5.json` | ~290 KB c/u | Tamaño + parseo |

Los SHA-256 de los ONNX son los `lfs.oid` publicados por Hugging Face. Si un archivo sigue corrupto tras los reintentos, la descarga falla de forma visible (`ModeloCorruptoException`) — nunca se marca `listo` con un modelo incompleto.

## Voces

### Voces Disponibles (`voces`)

| Código | Tipo |
|--------|------|
| `M1`–`M5` | Masculinas |
| `F1`–`F5` | Femeninas |

Cada voz tiene su JSON de estilo en `voice_styles/` con los parámetros de prosodia/tono/ritmo.

### Parámetros de Síntesis

| Parámetro | Rango | Default | Descripción |
|-----------|-------|---------|-------------|
| `voz` | M1–M5 / F1–F5 | `M1` | Estilo de voz |
| `steps` | 5–12 | `5` | Pasos de decodificación |
| `speed` | 0.7–2.0 | `1.1` | Velocidad de habla |
| `lang` | 31 códigos + `na` | `es` | Idioma de síntesis |

La configuración vive en `VoiceConfig` y se aplica con `MotorTts.cambiarVoz(voz)` antes del lote.

## Idiomas Soportados (31 + auto)

Ver tabla completa en [configuration.md](configuration.md#idiomas-soportados-31--auto).

## Estrategia de Descarga

### Flujo

```
1. Verificar disco → archivos existen + tamaño correcto
2. Verificar hash → SHA-256 en Isolate (solo ONNX)
3. Descargar → https://huggingface.co/Supertone/supertonic-3
4. Guardar → <app_support>/modelo/onnx/ y voice_styles/
```

### Resumibilidad

Descargas resumibles con `Dio`: header `Range` + modo append sobre un archivo `.part`.

### Gestión de Estado

**Controller**: `ModeloController` → `ModeloEstado`

| Campo | Descripción |
|-------|-------------|
| `listo` | ¿Modelo descargado y verificado? (gate del router) |
| `progreso` | 0.0 – 1.0 |
| `error` | Mensaje de error |
| `verificando` | Verificación en curso |

### Verificación de Integridad

El hash SHA-256 se calcula en un Isolate para no bloquear la UI. Los JSONs se validan por tamaño exacto + parseo.

## Inferencia

### Pipeline de Síntesis

```
1. Tokenizar texto (unicode_indexer.json)
2. Codificar estilo → embedding de voz (voice_styles/*.json)
3. Predecir duración + estimar vectores
4. Vocoder → muestras Float32
5. Insertar silencio entre fragmentos (26460 muestras)
```

### Calidad vs Velocidad

| Pasos | Calidad | Velocidad |
|-------|---------|-----------|
| 5 | Buena | Rápida |
| 8 | Muy buena | Moderada |
| 12 | Excelente | Lenta |

### Salida del Modelo

- **Formato**: Float32 PCM · **Frecuencia**: 44100 Hz · **Mono** · Rango -1.0 a 1.0

## Errores Comunes

| Error | Causa | Solución |
|-------|-------|---------|
| `OutOfMemory` | Modelo + audio en memoria | Reducir steps; el volcado a `_temp/` es automático |
| `InvalidGraph` | Modelo corrupto o incompatible | Re-descargar desde pantalla Modelo |
| `FileNotFound` | Modelo no descargado | Descargar desde pantalla Modelo |
| `ModeloCorruptoException` | Hash/tamaño inválido tras reintentos | Re-descargar; verificar conexión |

## Referencias

- [ONNX Runtime](https://onnxruntime.ai/)
- [Supertone/supertonic-3](https://huggingface.co/Supertone/supertonic-3)
- [flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)
