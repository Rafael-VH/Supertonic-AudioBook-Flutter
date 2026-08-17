# Supertonic 3 Model

The TTS model that converts text to speech — architecture, voices, and integration.

## Overview

| Property | Value |
|----------|-------|
| Model | Supertonic 3 |
| Creator | [Supertone Inc.](https://huggingface.co/Supertone/supertonic-3) |
| License | OpenRAIL-M |
| Type | Text-to-Speech (TTS) |
| Languages | 31 languages + auto |
| Size | ~400 MB total |
| Format | ONNX (4 model files) |

## What is Supertonic 3?

A multilingual neural TTS model that generates high-quality speech from text. Unlike cloud-based TTS (Google, Amazon, Azure), Supertonic runs **entirely on-device** — no internet required after model download.

**Key advantages**:
- **Privacy**: Text never leaves the device
- **Offline**: Works without internet
- **Free**: No API costs or usage limits
- **Fast**: CPU inference in ~1-3 seconds per chunk

## Model Architecture

Supertonic 3 uses a **diffusion-based** architecture with 4 neural networks:

```
Text Input
    │
    ▼
┌─────────────────┐
│ Text Encoder    │  Encode text → embeddings
│ (36.4 MB)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Duration        │  Predict phoneme durations
│ Predictor       │
│ (3.7 MB)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Vector          │  Denoise latent vectors
│ Estimator       │  (iterative refinement)
│ (256.5 MB)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Vocoder         │  Convert latents → audio
│ (101.4 MB)      │
└────────┬────────┘
         │
         ▼
   Audio Output (Float32 samples)
```

### How Diffusion Works

1. **Start** with random noise (latent vector)
2. **Iterate** N steps, each step reducing noise
3. **More steps** = higher quality, slower inference
4. **Final** latent vector → audio via vocoder

```dart
// Denoising loop (simplified)
for (var step = 0; step < totalStep; step++) {
  noisyLatent = vectorEstimator.denoise(
    noisyLatent,
    textEmbeddings,
    style,
    step,
    totalSteps,
  );
}
audio = vocoder.convert(noisyLatent);
```

## Model Files

### ONNX Models

| File | Size | SHA-256 | Purpose |
|------|------|---------|---------|
| `duration_predictor.onnx` | 3.7 MB | `c3eb9141...` | Predict phoneme durations |
| `text_encoder.onnx` | 36.4 MB | `c7befd5e...` | Encode text to embeddings |
| `vector_estimator.onnx` | 256.5 MB | `883ac868...` | Denoise latent vectors |
| `vocoder.onnx` | 101.4 MB | `085de76d...` | Convert latents to audio |

### Configuration Files

| File | Size | Purpose |
|------|------|---------|
| `tts.json` | 8.2 KB | Model configuration (sample rate, dimensions) |
| `unicode_indexer.json` | 277.7 KB | Unicode codepoint → model index mapping |

### Voice Style Files

| File | Size | Purpose |
|------|------|---------|
| `voice_styles/M1.json` | 291.7 KB | Male voice 1 style vectors |
| `voice_styles/M2.json` | 292.1 KB | Male voice 2 style vectors |
| `voice_styles/M3.json` | 290.2 KB | Male voice 3 style vectors |
| `voice_styles/M4.json` | 291.5 KB | Male voice 4 style vectors |
| `voice_styles/M5.json` | 291.5 KB | Male voice 5 style vectors |
| `voice_styles/F1.json` | 292.0 KB | Female voice 1 style vectors |
| `voice_styles/F2.json` | 292.4 KB | Female voice 2 style vectors |
| `voice_styles/F3.json` | 290.8 KB | Female voice 3 style vectors |
| `voice_styles/F4.json` | 291.8 KB | Female voice 4 style vectors |
| `voice_styles/F5.json` | 291.5 KB | Female voice 5 style vectors |

## Voices

### Available Voices

| Code | Type | Description |
|------|------|-------------|
| `M1`–`M5` | Male | 5 male voice variants |
| `F1`–`F5` | Female | 5 female voice variants |

### Voice Selection

```dart
// Change voice (reloads style file)
await motor.cambiarVoz('F1');

// Current voice is used in synthesis
final wav = await motor.sintetizar(
  'Hello world',
  steps: 5,
  speed: 1.0,
  lang: 'en',
);
```

### How Voices Work

Each voice is a **style embedding** — a vector that controls the voice characteristics:

```json
{
  "style_ttl": {
    "dims": [1, 128, 64],
    "data": [[[[0.123, ...]]]]
  },
  "style_dp": {
    "dims": [1, 128, 64],
    "data": [[[[0.456, ...]]]]
  }
}
```

- **`style_ttl`**: Controls vocal timbre and expression
- **`style_dp`**: Controls duration and rhythm

## Supported Languages

### 31 Languages

| Code | Language | Code | Language |
|------|----------|------|----------|
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
| `lv` | Latviešu | `na` | Auto (no language) |

### Language Handling

Language is applied via XML tags during preprocessing:

```dart
// Text is wrapped with language tags
text = '<es>Hola, ¿cómo estás?</es>';

// Model uses tags to select language-specific processing
```

**Korean/Japanese**: Special handling — max 120 chars per chunk (vs 300 for Latin scripts).

## Model Download

### Source

All files from: `https://huggingface.co/Supertone/supertonic-3/resolve/main`

### Download Strategy

```dart
const urlBase = 'https://huggingface.co/Supertone/supertonic-3/resolve/main';

// Download URL for each file
final url = '$urlBase/${archivo.ruta}';
// e.g. 'https://huggingface.co/.../onnx/vocoder.onnx'
```

### Resumable Downloads

Uses Dio with `Range` header for resumption:

```dart
await _dio.download(
  url,
  part.path,
  cancelToken: _activo,
  deleteOnError: false,
  fileAccessMode: FileAccessMode.append,
  options: Options(
    headers: {
      if (inicio > 0) 'range': 'bytes=$inicio-',
    },
  ),
);
```

### Verification

Each file verified after download:

| File Type | Verification |
|-----------|-------------|
| `.onnx` | SHA-256 hash match |
| `.json` | Size match + valid JSON parse |

```dart
Future<bool> _estaVerificado(File destino, ArchivoModelo archivo) async {
  if (!await destino.exists()) return false;
  final tamano = await destino.length();
  if (tamano != archivo.tamanoBytes) return false;
  if (archivo.sha256 != null) {
    return await _hashSha256(destino) == archivo.sha256;
  }
  return _esJsonValido(destino);
}
```

### Retry Logic

- 3 attempts per file
- On network error: preserve `.part` file, resume from byte offset
- On corruption: delete `.part`, restart from zero
- After 3 failures: throw `ModeloCorruptoException`

## Configuration (`tts.json`)

```json
{
  "ae": {
    "sample_rate": 44100,
    "base_chunk_size": 512
  },
  "ttl": {
    "chunk_compress_factor": 2,
    "latent_dim": 128
  }
}
```

| Key | Value | Description |
|-----|-------|-------------|
| `ae.sample_rate` | 44100 | Audio sample rate (Hz) |
| `ae.base_chunk_size` | 512 | Base audio chunk size |
| `ttl.chunk_compress_factor` | 2 | Latent compression factor |
| `ttl.latent_dim` | 128 | Latent vector dimension |

## Integration in App

### Directory Structure

```
<app_support>/
└── modelo/
    ├── onnx/
    │   ├── duration_predictor.onnx
    │   ├── text_encoder.onnx
    │   ├── vector_estimator.onnx
    │   ├── vocoder.onnx
    │   ├── tts.json
    │   └── unicode_indexer.json
    └── voice_styles/
        ├── M1.json
        ├── M2.json
        ├── ...
        └── F5.json
```

### Loading Flow

```
App Start
    │
    ▼
Splash Screen
    │
    ▼
Check: modelo verificado?
    │
    ├─ Yes → Dashboard
    │
    └─ No → Modelo Screen
              │
              ▼
         Download all files
              │
              ▼
         Verify integrity
              │
              ▼
         Dashboard
```

### Synthesis Flow

```
User taps "Process"
    │
    ▼
Load model (lazy)
    │
    ▼
For each text segment:
    │
    ├─ Preprocess text (NFKD, emojis, symbols)
    │
    ├─ Unicode → integer IDs
    │
    ├─ Run 4 ONNX models:
    │   ├─ duration_predictor
    │   ├─ text_encoder
    │   ├─ vector_estimator (N iterations)
    │   └─ vocoder
    │
    └─ Append silence between chunks
         │
         ▼
    Export audio (WAV/MP3/FLAC/OGG)
```

## Quality Settings

### Steps (5–12)

More denoising steps = higher quality:

| Steps | Quality | Speed |
|-------|---------|-------|
| 5 | Good | Fast |
| 8 | Better | Medium |
| 12 | Best | Slow |

### Speed (0.7–2.0)

Controls speech rate:

| Speed | Effect |
|-------|--------|
| 0.7 | Slow, clear |
| 1.0 | Normal |
| 1.1 | Default (slightly fast) |
| 2.0 | Very fast |

## Performance

| Metric | Value |
|--------|-------|
| Model load | ~2-5 seconds |
| Inference (5 steps) | ~1-2 seconds/chunk |
| Inference (12 steps) | ~3-5 seconds/chunk |
| Memory usage | ~500 MB peak |
| Audio output | 44100 Hz, PCM 16-bit |

## License

**OpenRAIL-M** (Open Responsible AI License - Modified)

- ✅ Free for commercial use
- ✅ Modification allowed
- ✅ Distribution allowed
- ⚠️ Must include license notice
- ⚠️ Must not be used for harmful purposes

See: [Hugging Face Model Card](https://huggingface.co/Supertone/supertonic-3)
