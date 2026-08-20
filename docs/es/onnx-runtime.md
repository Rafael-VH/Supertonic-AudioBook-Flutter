# ONNX Runtime

Cómo ONNX Runtime potencia el motor de inferencia TTS.

## Resumen

| Propiedad | Valor |
|----------|-------|
| Paquete | `flutter_onnxruntime: ^1.8.3` |
| Rol | Ejecutar modelos ML para síntesis de texto a voz |
| Ejecución | On-device, solo CPU (sin GPU) |
| Sesiones | 4 modelos ONNX cargados en paralelo |

## ¿Qué es ONNX?

**Open Neural Network Exchange** — un formato abierto para modelos ML. Modelos entrenados en PyTorch/TensorFlow se exportan a `.onnx` y corren en cualquier dispositivo compatible con ONNX Runtime.

**¿Por qué ONNX para este proyecto?**
- Sin dependencia de nube — corre 100 % local
- Sin GPU requerida — la inferencia por CPU es suficiente
- Multiplataforma — el mismo modelo funciona en Android, iOS y desktop
- Runtime liviano via `flutter_onnxruntime`

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                         │
│  ┌──────────────┐    ┌──────────────────────────────┐   │
│  │ MotorTts     │    │   supertonic_helper.dart      │   │
│  │ Supertonic   │───→│                              │   │
│  └──────────────┘    │  ┌────────────────────────┐  │   │
│                      │  │   TextToSpeech         │  │   │
│                      │  │   ┌──────────────────┐ │  │   │
│                      │  │   │ UnicodeProcessor  │ │  │   │
│                      │  │   └──────────────────┘ │  │   │
│                      │  └────────────────────────┘  │   │
│                      └──────────┬───────────────────┘   │
│                                 │                       │
└─────────────────────────────────┼───────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   flutter_onnxruntime    │
                    │   (ONNX Runtime)         │
                    └─────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ .onnx    │ │ .onnx    │ │ .onnx    │
              │ models   │ │ models   │ │ models   │
              └──────────┘ └──────────┘ └──────────┘
```

## Sesiones ONNX

Cuatro modelos se cargan como sesiones ONNX separadas:

| Sesión | Archivo | Tamaño | Propósito |
|---------|-----------|------|---------|
| `dpOrt` | `duration_predictor.onnx` | 3.7 MB | Predecir duraciones de fonemas |
| `textEncOrt` | `text_encoder.onnx` | 36.4 MB | Codificar texto a embeddings |
| `vectorEstOrt` | `vector_estimator.onnx` | 256.5 MB | Des-ruidizar vectores latentes |
| `vocoderOrt` | `vocoder.onnx` | 101.4 MB | Convertir latentes a audio |

### Carga

Las 4 sesiones cargan en paralelo al iniciar:

```dart
final ort = OnnxRuntime();
final models = ['duration_predictor', 'text_encoder', 'vector_estimator', 'vocoder'];

final sessions = await Future.wait(models.map((name) async {
  final path = '$dir/$name.onnx';
  return ort.createSession(path);
}));
```

### Ciclo de Vida de Sesiones

- **Carga lazy**: la primera síntesis dispara `loadTextToSpeech()`
- **Singleton**: una instancia por cambio de voz
- **Sin GPU**: `useGpu: false` (el modo GPU lanza excepción)

## Pipeline de Inferencia

### 1. Preprocesamiento de Texto

```dart
String preprocessText(String text, String lang) {
  // Descomposición NFKD (sílabas Hangul → Jamo)
  text = _applyNfkdDecomposition(text);

  // Eliminar emojis, reemplazar símbolos
  text = text.replaceAll(RegExp(r'[\u{1F600}-...]'), '');

  // Normalizar puntuación y espaciado
  text = text.replaceAll(' ,', ',');

  // Agregar tags de idioma
  text = '<$lang>$text</$lang>';

  return text;
}
```

### 2. Procesamiento Unicode

```dart
class UnicodeProcessor {
  final Map<int, int> indexer;  // Codepoint Unicode → índice del modelo

  Map<String, dynamic> call(List<String> textList, List<String> langList) {
    // Convertir texto a IDs enteros
    // Generar máscaras de atención
    return {'textIds': textIds, 'textMask': mask};
  }
}
```

### 3. Predicción de Duración

```dart
final dpResult = await dpOrt.run({
  'text_ids': textIdsTensor,
  'style_dp': style.dp,
  'text_mask': textMaskTensor,
});
// Salida: duraciones predichas por fonema
```

### 4. Codificación de Texto

```dart
final textEncResult = await textEncOrt.run({
  'text_ids': textIdsTensor,
  'style_ttl': style.ttl,
  'text_mask': textMaskTensor,
});
// Salida: embeddings de texto
```

### 5. Loop de Des-Ruidizado

Refinamiento iterativo de vectores latentes:

```dart
for (var step = 0; step < totalStep; step++) {
  final result = await vectorEstOrt.run({
    'noisy_latent': noisyLatent,
    'text_emb': textEncResult,
    'style_ttl': style.ttl,
    'text_mask': textMaskTensor,
    'latent_mask': latentMaskTensor,
    'total_step': totalStepTensor,
    'current_step': stepTensor,
  });
  // Actualizar noisyLatent con la salida des-ruidizada
}
```

**Más pasos = mejor calidad, inferencia más lenta.**

### 6. Vocoder

```dart
final vocoderResult = await vocoderOrt.run({
  'latent': noisyLatent,
});
// Salida: muestras de audio Float32
```

## Operaciones con Tensores

### Crear Tensores

```dart
// Tensor Float32
Future<OrtValue> _toTensor(dynamic array, List<int> dims) async {
  final flat = _flattenList<double>(array);
  return await OrtValue.fromList(Float32List.fromList(flat), dims);
}

// Tensor Int64
Future<OrtValue> _intToTensor(List<List<int>> array, List<int> dims) async {
  final flat = array.expand((row) => row).toList();
  return await OrtValue.fromList(Int64List.fromList(flat), dims);
}

// Tensor escalar
Future<OrtValue> _scalarToTensor(List<double> array, List<int> dims) async {
  return await OrtValue.fromList(Float32List.fromList(array), dims);
}
```

### Leer Resultados

```dart
final result = await session.run({...inputs...});
final output = await result.values.first.asList();
// Devuelve List<double> o List<int>
```

## Segmentación de Texto

Los textos largos se dividen en chunks antes de inferir:

```dart
List<String> _chunkText(String text, {int maxLen = 300}) {
  // Dividir por párrafos, luego por oraciones
  // Máx 300 chars por chunk (120 para coreano/japonés)
  // Cada chunk se procesa independientemente y luego se concatena
}
```

**Límites por idioma**:
- Scripts latinos: máx 300 chars
- Coreano/Japonés: máx 120 chars

## Concatenación de Audio

Múltiples chunks producen arrays de audio separados. Se concatenan con silencio:

```dart
if (wavCat == null) {
  wavCat = wav;
} else {
  wavCat = [
    ...wavCat,
    ...List<double>.filled((silenceDuration * sampleRate).floor(), 0.0),
    ...wav,
  ];
}
```

## Gestión de Memoria

### Durante la Inferencia

- Tensores creados via `OrtValue.fromList()`
- Resultados extraídos via `.asList()`
- Tensores intermedios liberados por GC después de `session.run()`

### Procesamiento por Lotes

- Un chunk a la vez (sin batching)
- Vectores latentes asignados por chunk
- Sin estado persistente entre chunks

## Características de Rendimiento

| Métrica | Valor |
|--------|-------|
| Arranque en frío | ~2-5 segundos (cargar 4 modelos) |
| Inferencia tibia | ~1-3 segundos por chunk |
| Pico de memoria | ~500 MB (modelos + tensores) |
| Uso de CPU | Single-threaded |

## Manejo de Errores

```dart
// GPU no soportada
if (useGpu) throw Exception('GPU mode not supported yet');

// Idioma inválido
if (!isValidLang(lang)) {
  throw ArgumentError('Invalid language: $lang');
}
```

## Decisiones de Diseño Clave

### 1. Carga Lazy

Los modelos cargan en la primera síntesis, no al arrancar la app. Esto mantiene el arranque rápido (~200 ms) aceptando la penalización de arranque en frío en el primer uso.

### 2. Sin GPU

El modo GPU está explícitamente deshabilitado. El modelo Supertonic 3 está diseñado para inferencia por CPU, y el soporte de GPU requeriría código adicional específico por plataforma.

### 3. Isolate para Hashing

La verificación del modelo (SHA-256) corre en un isolate separado para no bloquear la UI durante la verificación de descarga.

### 4. Chunks Fijos

El texto se divide en límites fijos de caracteres, no por fronteras de oraciones. Simplifica el pipeline manteniendo calidad aceptable.
