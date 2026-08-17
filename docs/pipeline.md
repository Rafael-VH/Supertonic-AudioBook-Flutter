# Audio Processing Pipeline

How Markdown files become audiobooks — the complete transformation flow.

## Overview

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Read .md   │ →  │   Clean      │ →  │  Segment     │ →  │  Synthesize  │
│  (dart:io)  │    │  (regex)     │    │  (pure)      │    │  (ONNX)      │
└─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                                                                    │
┌─────────────┐    ┌──────────────┐    ┌──────────────┐            │
│  Publish    │ ←  │  Convert     │ ←  │  Export      │ ←──────────┘
│  (rename)   │    │  (FFmpeg)    │    │  (WAV/MP3..) │
└─────────────┘    └──────────────┘    └──────────────┘
```

## Pipeline Stages

### 1. Read File

**Use case**: `RepositorioArchivos.leerArchivo()`

- Reads file as UTF-8 string
- Returns raw Markdown content
- Throws on file not found / permission error → `ResultadoProceso.error`

### 2. Clean Markdown

**Use case**: `limpiarMarkdown()` (pure function)

Strips all Markdown syntax in order:

| Step | Regex Pattern | Action |
|------|--------------|--------|
| 1 | `~~~.*?~~~` | Remove code blocks |
| 2 | `` ```.*?``` `` | Remove fenced code blocks |
| 3 | `^#{1,6}\s*` | Remove headings |
| 4 | `\*{3}...\*{3}` | Remove bold (`***`) |
| 5 | `\*{2}...\*{2}` | Remove italic (`**`) |
| 6 | `\*{1}...\*{1}` | Remove emphasis (`*`) |
| 7 | `_{3}..._{3}` | Remove bold (`___`) |
| 8 | `_{2}..._{2}` | Remove italic (`__`) |
| 9 | `_{1}..._{1}` | Remove emphasis (`_`) |
| 10 | `` `{1,3}...`{1,3} `` | Remove inline code |
| 11 | `![alt](url)` | Remove images (keep alt text) |
| 12 | `[text](url)` | Remove links (keep text) |
| 13 | `^\s*>\s?` | Remove blockquotes |
| 14 | `^-{3,}$` | Remove horizontal rules |
| 15 | `^[-*+]\s+` | Remove unordered list markers |
| 16 | `^\d{1,3}[.)]\s+` | Remove ordered list markers |
| 17 | `\n{3,}` | Collapse multiple newlines |

**Key decisions**:
- Abbreviations protected (Dr., Sr., etc.) — won't split on these
- Anchored patterns prevent false positives (e.g. `2 * 3 * 4` stays as-is)
- Empty result after cleaning → `ResultadoProceso.omitido`

### 3. Segment Text

**Use case**: `segmentarTexto()` (pure function)

Splits clean text into TTS-ready chunks:

```
Step 1: Merge short paragraphs (< 200 chars) into buffer
Step 2: Split long paragraphs (> 1500 chars) by sentences
Step 3: Split oversized sentences by words
Step 4: Split oversized words by characters (last resort)
```

**Constants**:
- `maxCharsPerSegment = 1500` — max characters per audio fragment
- `mergeThreshold = 200` — paragraphs shorter than this merge with next

**Abbreviation handling**:
```
Dr. García → Dr\x00 García  (protect)
.split('. ')               (split)
Dr. García                  (restore)
```

### 4. Synthesize

**Use case**: `MotorTts.sintetizar()` → `MotorTtsSupertonic`

Converts text segments to Float32 audio samples:

```dart
final wav = await motor.sintetizar(
  texto,
  steps: steps,      // 5–12, higher = better quality
  speed: speed,      // 0.7–2.0
  lang: lang,        // 'es', 'en', etc.
);
```

**Technology**: Supertonic 3 via `flutter_onnxruntime`

**Memory management**:
- Fragments accumulated in memory
- When `memoriaAcumulada > presupuesto` → flush to disk via `wavAppend()`
- Mobile threshold: 64 MB (prevents OOM)
- Desktop threshold: 500 MB

**Between fragments**: Insert `silenceSamples` (26460) zeros for natural pauses.

### 5. Export

**Use case**: `ExportadorAudio` → `ExportadorAudioFfmpeg`

Two paths depending on memory state:

#### Path A: All in memory (small files)

```dart
for (final formato in formatosUnicos) {
  final temporal = _nuevoTemporal(dirSalida, formato, temporales);
  await exportador.escribirAudio(fragmentos, temporal, formato);
  salidas.add((temporal, '$rutaBase.$formato'));
}
```

#### Path B: Partial flush (large files)

```dart
// Already flushed to WAV, now convert from WAV
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

**Format support**:

| Format | Method | Technology |
|--------|--------|------------|
| WAV | `escribirAudio()` | Dart native (`wav_io.dart`) |
| MP3 | `convertirDesdeWav()` | FFmpeg |
| FLAC | `convertirDesdeWav()` | FFmpeg |
| OGG | `convertirDesdeWav()` | FFmpeg |

### 6. Publish

**Action**: Atomic rename from temp → final path

```dart
File(origen).renameSync(destino);
```

**Ordering** (WAV last):
1. Non-WAV formats first
2. WAV last — if a format fails, previous WAV stays intact

**Cancel semantics**:
- On cancel, only publish to destinations that didn't exist before
- Preserves complete audio from previous runs
- Never replaces a complete file with truncated output

**Error handling**:
- `EACCES` (error 13) — file in use, skip
- `ERROR_SHARING_VIOLATION` (error 32) — Windows file lock, skip

### 7. Cleanup

All temporary files are deleted in `finally` block:

```dart
finally {
  for (final temporal in temporales) {
    try { File(temporal).deleteSync(); } catch (_) {}
  }
}
```

## Batch Processing

When processing multiple files (Home screen):

```
for each archivo in seleccion:
  1. ProcesarArchivo.procesar(archivo, ...)
  2. Update progress (progresoActual / progresoTotal)
  3. Log result (ok / omitido / error)
  4. Continue to next file
```

**Concurrency**: Single-threaded. Motor TTS does not support concurrent synthesis.

**Cancellation**:
- User taps "Cancel" → sets `cancelar = true`
- Current segment finishes, then loop breaks
- Partial audio exported via normal publish flow

## Voice Preview

Quick synthesis without full pipeline:

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

## Data Flow Summary

```
Input:  .md file (UTF-8)
        ↓
Clean:  Plain text (no Markdown syntax)
        ↓
Segment: List<String> (≤1500 chars each)
        ↓
Synthesize: List<Float32List> (audio samples + silence)
        ↓
Export: Temp files (WAV, MP3, FLAC, OGG)
        ↓
Publish: Final files (atomic rename)
        ↓
Cleanup: Delete all temporaries
```
