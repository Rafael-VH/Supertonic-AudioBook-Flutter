# Pipeline de Procesamiento de Audio

Cómo los archivos Markdown se convierten en audiolibros — el flujo completo de transformación.

## Resumen

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Leer .md   │ →  │   Limpiar    │ →  │  Segmentar   │ →  │  Sintetizar  │
│  (dart:io)  │    │  (regex)     │    │  (puro)      │    │  (ONNX)      │
└─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                                                                    │
┌─────────────┐    ┌──────────────┐    ┌──────────────┐            │
│  Publicar   │ ←  │  Convertir   │ ←  │  Exportar    │ ←──────────┘
│  (rename)   │    │  (FFmpeg)    │    │  (WAV/MP3..) │
└─────────────┘    └──────────────┘    └──────────────┘
```

## Etapas del Pipeline

### 1. Leer Archivo

**Caso de uso**: `RepositorioArchivos.leerArchivo()`

- Lee el archivo como string UTF-8
- Devuelve contenido Markdown crudo
- Lanza excepción si no se encuentra archivo / error de permiso → `ResultadoProceso.error`

### 2. Limpiar Markdown

**Caso de uso**: `limpiarMarkdown()` (función pura)

Elimina toda la sintaxis Markdown en orden:

| Paso | Patrón Regex | Acción |
|------|-------------|--------|
| 1 | `~~~.*?~~~` | Eliminar bloques de código |
| 2 | `` ```.*?``` `` | Eliminar bloques de código con fence |
| 3 | `^#{1,6}\s*` | Eliminar encabezados |
| 4 | `\*{3}...\*{3}` | Eliminar negrita (`***`) |
| 5 | `\*{2}...\*{2}` | Eliminar cursiva (`**`) |
| 6 | `\*{1}...\*{1}` | Eliminar énfasis (`*`) |
| 7 | `_{3}..._{3}` | Eliminar negrita (`___`) |
| 8 | `_{2}..._{2}` | Eliminar cursiva (`__`) |
| 9 | `_{1}..._{1}` | Eliminar énfasis (`_`) |
| 10 | `` `{1,3}...`{1,3} `` | Eliminar código inline |
| 11 | `![alt](url)` | Eliminar imágenes (conservar texto alt) |
| 12 | `[text](url)` | Eliminar links (conservar texto) |
| 13 | `^\s*>\s?` | Eliminar blockquotes |
| 14 | `^-{3,}$` | Eliminar reglas horizontales |
| 15 | `^[-*+]\s+` | Eliminar marcadores de listas desordenadas |
| 16 | `^\d{1,3}[.)]\s+` | Eliminar marcadores de listas ordenadas |
| 17 | `\n{3,}` | Colapsar saltos de línea múltiples |

**Decisiones clave**:
- Abreviaturas protegidas (Dr., Sr., etc.) — no se dividen en estos puntos
- Patrones anclados previenen falsos positivos (ej. `2 * 3 * 4` se mantiene)
- Resultado vacío después de limpiar → `ResultadoProceso.omitido`

### 3. Segmentar Texto

**Caso de uso**: `segmentarTexto()` (función pura)

Divide el texto limpio en chunks listos para TTS:

```
Paso 1: Fusionar párrafos cortos (< 200 chars) en buffer
Paso 2: Dividir párrafos largos (> 1500 chars) por oraciones
Paso 3: Dividir oraciones oversized por palabras
Paso 4: Dividir palabras oversized por caracteres (último recurso)
```

**Constantes**:
- `maxCharsPerSegment = 1500` — máximo de caracteres por fragmento de audio
- `mergeThreshold = 200` — párrafos más cortos que este valor se fusionan con el siguiente

**Manejo de abreviaturas**:
```
Dr. García → Dr\x00 García  (proteger)
.split('. ')               (dividir)
Dr. García                  (restaurar)
```

### 4. Sintetizar

**Caso de uso**: `MotorTts.sintetizar()` → `MotorTtsSupertonic`

Convierte segmentos de texto en muestras de audio Float32:

```dart
final wav = await motor.sintetizar(
  texto,
  steps: steps,      // 5–12, más = mejor calidad
  speed: speed,      // 0.7–2.0
  lang: lang,        // 'es', 'en', etc.
);
```

**Tecnología**: Supertonic 3 via `flutter_onnxruntime`

**Gestión de memoria**:
- Fragmentos acumulados en memoria
- Cuando `memoriaAcumulada > presupuesto` → volcar a disco via `wavAppend()`
- Umbral móvil: 64 MB (previene OOM)
- Umbral desktop: 500 MB

**Entre fragmentos**: Se insertan `silenceSamples` (26460) ceros para pausas naturales.

### 5. Exportar

**Caso de uso**: `ExportadorAudio` → `ExportadorAudioFfmpeg`

Dos caminos según el estado de memoria:

#### Camo A: Todo en memoria (archivos pequeños)

```dart
for (final formato in formatosUnicos) {
  final temporal = _nuevoTemporal(dirSalida, formato, temporales);
  await exportador.escribirAudio(fragmentos, temporal, formato);
  salidas.add((temporal, '$rutaBase.$formato'));
}
```

#### Camino B: Volcado parcial (archivos grandes)

```dart
// Ya volcado a WAV, ahora convertir desde WAV
await exportador.wavAppend(fragmentos, rutaWavTrabajo);
for (final formato in formatosUnicos) {
  if (formato == 'wav') {
    salidas.add((rutaWavTrabajo, '$rutaBase.wav'));
  } else {
    final temporal = _nuevoTemporal(dirSalida, formato, temporales);
    await exportador.convertirDesdeWav(rutaWavTrabajo, temporal, formato);
    salidas.add((temporal, '$rutaBase.$formato'));
  }
}
```

**Formatos soportados**:

| Formato | Método | Tecnología |
|---------|--------|------------|
| WAV | `escribirAudio()` | Dart nativo (`wav_io.dart`) |
| MP3 | `convertirDesdeWav()` | FFmpeg |
| FLAC | `convertirDesdeWav()` | FFmpeg |
| OGG | `convertirDesdeWav()` | FFmpeg |

### 6. Publicar

**Acción**: Rename atómico de temporal → ruta final

```dart
File(origen).renameSync(destino);
```

**Orden** (WAV al final):
1. Formatos no-WAV primero
2. WAV al final — si falla un formato, el WAV previo se mantiene intacto

**Semántica de cancelación**:
- Al cancelar, solo se publica en destinos que no existían antes
- Preserva audio completo de corridas anteriores
- Nunca reemplaza un archivo completo con output truncado

**Manejo de errores**:
- `EACCES` (error 13) — archivo en uso, saltar
- `ERROR_SHARING_VIOLATION` (error 32) — bloqueo de archivo Windows, saltar

### 7. Limpieza

Todos los archivos temporales se eliminan en el bloque `finally`:

```dart
finally {
  for (final temporal in temporales) {
    try { File(temporal).deleteSync(); } catch (_) {}
  }
}
```

## Procesamiento por Lotes

Al procesar múltiples archivos (pantalla Home):

```
for each archivo in seleccion:
  1. ProcesarArchivo.procesar(archivo, ...)
  2. Actualizar progreso (progresoActual / progresoTotal)
  3. Registrar resultado (ok / omitido / error)
  4. Continuar al siguiente archivo
```

**Concurrencia**: De un solo hilo. El motor TTS no soporta síntesis concurrente.

**Cancelación**:
- Usuario toca "Cancelar" → establece `cancelar = true`
- El segmento actual termina, luego el loop se rompe
- Audio parcial se exporta via flujo normal de publicación

## Vista Previa de Voz

Síntesis rápida sin pipeline completo:

```dart
final wav = await motor.sintetizar(
  'Texto de muestra...',
  steps: defaultTtsSteps,
  speed: defaultSpeed,
  lang: lang,
);
await exportador.escribirAudio([wav], ruta, 'wav');
await reproductor.reproducir(ruta);
```

## Resumen del Flujo de Datos

```
Input:  Archivo .md (UTF-8)
        ↓
Clean:  Texto plano (sin sintaxis Markdown)
        ↓
Segment: List<String> (≤1500 chars cada uno)
        ↓
Synthesize: List<Float32List> (muestras de audio + silencio)
        ↓
Export: Archivos temporales (WAV, MP3, FLAC, OGG)
        ↓
Publish: Archivos finales (rename atómico)
        ↓
Cleanup: Eliminar todos los temporales
```
