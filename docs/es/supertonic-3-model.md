# Modelo Supertonic 3

Modelo de síntesis de texto a voz (TTS) usado en la aplicación.

## Resumen

Supertonic 3 es un modelo de TTS basado en transformer que genera audio de alta calidad a partir de texto. El modelo usa arquitectura de decodificación autoregresiva con voces condicionadas por estilo.

## Especificaciones

| Propiedad | Valor |
|-----------|-------|
| Tipo | Transformer TTS (autoregresivo) |
| Tamaño | ~400 MB |
| Formato | ONNX |
| Formato de audio | Float32 PCM |
| Frecuencia de muestreo | 44100 Hz |
| Canales | Mono |
| Pasos de inferencia | 5–12 (más = mejor calidad) |

## Voces

### Voces Disponibles

| Código | Tipo | Género |
|--------|------|--------|
| `M1`–`M5` | Masculina | 5 opciones |
| `F1`–`F5` | Femenina | 5 opciones |

### Selección de Voz

```dart
// En configuración TTS
configTts: Record(
  voz: 'M1',      // Código de voz
  lang: 'es',     // Idioma
  steps: 5,       // Pasos de inferencia
  speed: 1.1,     // Velocidad
)
```

### Archivos de Estilo

Cada voz tiene un archivo de estilo JSON:

```
voice_styles/
├── M1.json
├── M2.json
├── M3.json
├── M4.json
├── M5.json
├── F1.json
├── F2.json
├── F3.json
├── F4.json
└── F5.json
```

Cada JSON contiene los parámetros de estilo de la voz (prosodia, tono, ritmo).

## Idiomas Soportados (31 + auto)

| Código | Idioma | Código | Idioma |
|--------|--------|--------|--------|
| `es` | Español | `nl` | Nederlands |
| `en` | English | `pl` | Polski |
| `fr` | Français | `pt` | Português |
| `de` | Deutsch | `ro` | Română |
| `it` | Italiano | `ru` | Русский |
| `ar` | العربية | `sk` | Slovenčina |
| `bg` | Български | `sl` | Slovenščina |
| `cs` | Čeština | `sv` | Svenska |
| `da` | Dansk | `tr` | Türkçe |
| `el` | Ελληνικά | `uk` | Українська |
| `et` | Eesti | `vi` | Tiếng Việt |
| `fi` | Suomi | `hi` | हिन्दी |
| `hr` | Hrvatski | `ja` | 日本語 |
| `hu` | Magyar | `ko` | 한국어 |
| `id` | Bahasa Indonesia | `lt` | Lietuvių |
| `lv` | Latviešu | `na` | Auto (sin idioma) |

## Estrategia de Descarga

### Flujo de Descarga

```
1. Verificar disco → modelo existe + tamaño correcto
2. Verificar hash → SHA-256 en Isolate
3. Descargar modelo → desde CDN o repositorio
4. Guardar en → <app_support>/modelo/onnx/
5. Guardar voice_styles → <app_support>/modelo/voice_styles/
```

### Gestión de Estado

```dart
class ModeloEstado {
  final bool modeloDisponible;    // ¿Está descargado y verificado?
  final double progreso;          // 0.0 – 1.0
  final String? error;            // Mensaje de error
  final bool verificando;         // Verificación en curso
}
```

### Verificación de Integridad

```dart
// En ModeloManager
final hash = await compute(_calcularHash, modeloPath);
if (hash != hashEsperado) {
  throw Exception('Modelo corrupto');
}
```

**Cálculo de hash**:
- Usa `compute()` para ejecutar en Isolate separado
- No bloquea la UI
- Algoritmo: SHA-256

### Almacenamiento

```
<app_support>/
└── modelo/
    ├── onnx/
    │   └── model.onnx         # Pesos del modelo (~400 MB)
    └── voice_styles/
        ├── M1.json            # Voz masculina 1
        ├── M2.json            # Voz masculina 2
        ├── ...
        └── F5.json            # Voz femenina 5
```

### Resumibilidad

La descarga soporta resumir desde el último punto:

```dart
// Dio soporta descargas con headers Range
final response = await dio.download(
  url,
  savePath,
  options: Options(headers: {'Range': 'bytes=$bytesDescargados-'}),
);
```

## Inferencia

### Pipeline de Síntesis

```
1. Tokenizar texto → tokens
2. Codificar estilo → embedding de voz
3. Decodificar autoregresivamente → secuencia de frames
4. Decodificar waveform → muestras Float32
5. Insertar silencio entre fragmentos
```

### Parámetros de Inferencia

| Parámetro | Rango | Default | Descripción |
|-----------|-------|---------|-------------|
| `steps` | 5–12 | 5 | Pasos de decodificación |
| `speed` | 0.7–2.0 | 1.1 | Velocidad de habla |
| `lang` | 31 códigos | `es` | Idioma de síntesis |

### Calidad vs Velocidad

| Pasos | Calidad | Velocidad |
|-------|---------|-----------|
| 5 | Buena | Rápida |
| 8 | Muy buena | Moderada |
| 12 | Excelente | Lenta |

### Salida del Modelo

- **Formato**: Float32 PCM
- **Frecuencia**: 44100 Hz
- **Canales**: Mono
- **Rango**: -1.0 a 1.0

## Optimizaciones

### Volcado de Memoria

Cuando la memoria acumulada excede el presupuesto (64 MB en móvil, 500 MB en desktop):

```dart
if (memoriaAcumulada > presupuesto) {
  await exportador.wavAppend(fragmentos, rutaWavTrabajo);
  fragmentos.clear();
}
```

### Sesiones Reutilizadas

La sesión ONNX se mantiene abierta entre inferencias para evitar el overhead de carga.

### Isolate para Verificación

El hash SHA-256 se calcula en un Isolate separado para no bloquear la UI.

## Errores Comunes

| Error | Causa | Solución |
|-------|-------|---------|
| `OutOfMemory` | Modelo + audio en memoria | Reducir steps, incrementar volcado |
| `InvalidGraph` | Modelo corrupto o incompatible | Re-descargar modelo |
| `FileNotFound` | Modelo no descargado | Descargar desde pantalla Modelo |
| `Timeout` | Descarga lenta o sin conexión | Reintentar conexión |

## Tests

### Mock de MotorTts

Para tests unitarios de dominio:

```dart
class MockMotorTts extends Mock implements MotorTts {}
```

### Tests de Integración

El test de `ProcesarArchivo` usa el modelo real para verificar el pipeline completo.

## Referencias

- [ONNX Runtime](https://onnxruntime.ai/)
- [Supertonic TTS](https://supertonic.ai/)
- [flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)
