# ONNX Runtime

Motor de inferencia ONNX para síntesis TTS en Flutter.

## Resumen

Flutter OnnxRuntime provee ejecución de modelos ONNX en Flutter con soporte multi-plataforma (Android, iOS, Windows, macOS, Linux).

## Instalación

```yaml
dependencies:
  flutter_onnxruntime: ^1.20.0
```

## Uso en el Proyecto

El proyecto usa `flutter_onnxruntime` en `MotorTtsSupertonic` (`features/convert/data/repositories/motor_tts.dart`) para:

1. **Cargar el modelo** Supertonic 3 desde disco
2. **Inferir** texto → muestras de audio Float32
3. **Gestionar sesiones** de inferencia con memoria segura

## Arquitectura de Inferencia

```
┌─────────────────────────────────────────────────┐
│                MotorTtsSupertonic                │
│                                                  │
│  ┌─────────────┐    ┌─────────────────────────┐  │
│  │ ModeloLoad  │ ──→│ InferenceSession        │  │
│  │ (Isolate)   │    │ (ONNX Runtime)          │  │
│  └─────────────┘    └─────────────────────────┘  │
│         │                      │                  │
│         ▼                      ▼                  │
│  ┌─────────────┐    ┌─────────────────────────┐  │
│  │  Archivo    │    │   Tensores de Salida    │  │
│  │  .onnx      │    │   (Float32List)         │  │
│  └─────────────┘    └─────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Sesiones de Inferencia

### Crear Sesión

```dart
final session = await OnnxRuntime.createSession(modeloPath);
```

**Parámetros**:
- `modeloPath`: Ruta al archivo `.onnx` en disco

### Ejecutar Inferencia

```dart
final inputTensor = OnnxTensor.createTensor([texto]);
final outputMap = await session.run({
  'input_text': inputTensor,
});
```

**Tensores de entrada**:
- `input_text`: Texto a sintetizar
- `steps`: Número de pasos de inferencia (5–12)
- `speed`: Velocidad de habla (0.7–2.0)
- `lang`: Código de idioma

**Tensores de salida**:
- `audio_samples`: Float32List con muestras de audio

### Liberar Recursos

```dart
await session.close();
```

## Gestión de Memoria

### Presupuesto por Plataforma

| Plataforma | Umbral | Descripción |
|------------|--------|-------------|
| Desktop | 500 MB | Suficiente RAM para chunking extenso |
| Móvil | 64 MB | Volcado frecuente a disco |

### Volcado a Disco

Cuando `memoriaAcumulada > presupuesto`:

```dart
if (memoriaAcumulada > presupuesto) {
  await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
  fragmentos.clear();  // Liberar memoria
}
```

### Fragmentos por Defecto

- Los fragmentos se acumulan en memoria como `List<Float32List>`
- Se insertan `silenceSamples` (26460) entre fragmentos
- El volcado se hace en el mismo thread de inferencia

## Carga del Modelo

### Proceso

1. **Verificar disco**: Comprobar que el modelo existe y tiene el tamaño correcto
2. **Verificar hash**: SHA-256 en Isolate para no bloquear UI
3. **Cargar modelo**: Crear `InferenceSession` en hilo de fondo
4. **Cache**: Mantener la sesión abierta para inferencias subsiguientes

### Tiempos de Carga

| Fase | Tiempo típico |
|------|---------------|
| Verificación SHA-256 | < 1s |
| Carga del modelo | 2–5s (depende del dispositivo) |
| Primera inferencia | 1–3s (calentamiento) |

## Errores Comunes

| Error | Causa | Solución |
|-------|-------|---------|
| `OutOfMemoryError` | Modelo + audio en memoria | Reducir pasos, incrementar volcado |
| `InvalidGraph` | Modelo corrupto | Re-descargar modelo |
| `InvalidNode` | Versión incompatible de Runtime | Actualizar `flutter_onnxruntime` |
| `FileNotFound` | Modelo no descargado | Descargar desde pantalla Modelo |

## Tests

### Mock de MotorTts

Para tests unitarios de dominio, se usa un mock:

```dart
class MockMotorTts extends Mock implements MotorTts {}
```

### Tests de Integración

El test de `ProcesarArchivo` usa el motor real con un modelo pequeño de prueba.

## Plataformas Soportadas

| Plataforma | Estado | Backend |
|------------|--------|---------|
| Android | ✅ | NNAPI / CPU |
| iOS | ✅ | CoreML / CPU |
| Windows | ✅ | DirectML / CPU |
| macOS | ✅ | CoreML / CPU |
| Linux | ✅ | CPU |
| Web | ❌ | No soportado |

## Configuración por Plataforma

### Android

```xml
<!-- android/app/build.gradle -->
android {
    defaultConfig {
        minSdkVersion 21
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
        }
    }
}
```

### iOS

```ruby
# ios/Podfile
platform :ios, '13.0'
```

## Rendimiento

### Optimizaciones

- **Sesiones reutilizadas**: La sesión ONNX se mantiene abierta entre inferencias
- **Volcado bajo demanda**: Solo se exporta a disco cuando la memoria lo requiere
- **Isolate para verificación**: SHA-256 no bloquea el hilo principal

### Benchmarks Típicos

| Dispositivo | Inferencia (1000 chars) |
|-------------|------------------------|
| iPhone 14 | ~2s |
| Samsung S23 | ~2.5s |
| MacBook Pro M2 | ~1.5s |
| Desktop Ryzen | ~1s |
