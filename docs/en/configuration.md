# Configuration

Technical constants, preferences and runtime configuration.

## Technical Constants

### Pipeline Configuration (`shared/data/config.dart`)

| Constant | Value | Description |
|-----------|-------|-------------|
| `silenceDurationSecs` | `0.6` | Seconds of silence between fragments |
| `silenceSamples` | `26460` | Samples at 44100 Hz × 0.6 s |
| `memoriaSafeMarginBytes` | `524288000` | Desktop RAM budget (500 MB) |
| `memoriaSafeMarginBytesMovil` | `67108864` | Mobile RAM budget (64 MB) |
| `subtiposAudio` | Map | Audio subtype per format |

### Product Defaults (`shared/domain/constants/producto.dart`)

| Constant | Value | Description |
|-----------|-------|-------------|
| `defaultVoice` | `'M1'` | Default voice |
| `defaultLang` | `'es'` | Default synthesis language |
| `defaultTtsSteps` | `5` | Default TTS inference steps (range 5–12) |
| `defaultSpeed` | `1.1` | Default speech speed (range 0.7–2.0) |

### Segmentation Configuration (`features/convert/domain/use_cases/segmentar_texto.dart`)

| Constant | Value | Description |
|-----------|-------|-------------|
| `maxCharsPerSegment` | `1500` | Max characters per TTS fragment |
| `mergeThreshold` | `200` | Paragraphs shorter than this merge with the next |

### Output Formats

```dart
// features/convert/domain/use_cases/formato.dart
const formatosNativos = ['wav', 'flac', 'ogg', 'mp3'];

// HomeController default:
['mp3']
```

## Voices

### Available Voices (`voces`)

| Code | Type |
|--------|------|
| `M1`–`M5` | Male voices |
| `F1`–`F5` | Female voices |

### Supported Languages (31 + auto)

| Code | Language | Code | Language |
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
| `lv` | Latviešu | `na` | Auto (no language) |

## User Preferences

### Storage

- **Location**: `<app_documents>/preferencias.json`
- **Format**: JSON key-value pairs
- **Implementation**: `PreferenciasJsonLocal` (own repository over a JSON file — does not use the `shared_preferences` package)

### Preference Keys

| Key | Type | Default | Description |
|-------|------|-------------|-------------|
| `tema_oscuro` | `bool` | `false` | Dark mode enabled |
| `estilo` | `String` | `'default'` | Visual style variant |
| `idioma` | `String` | `'es'` | Interface language |
| `onboarding_visto` | `bool` | `false` | Onboarding completed |
| `carpeta_in` | `String` | `<base>/archivos` | Input folder |
| `carpeta_out` | `String` | `<base>/audio` | Output folder |
| `voz` | `String` | `'M1'` | Selected voice |
| `steps` | `int` | `5` | TTS steps (5–12) |
| `speed` | `double` | `1.1` | Speech speed (0.7–2.0) |
| `lang_voz` | `String` | `'es'` | Voice language |
| `formatos` | `List<String>` | `['mp3']` | Output formats |

### The 3 JSON Files

Each repository is an independent instance of `PreferenciasJsonLocal`, injected in `main.dart`:

| File | Provider | Content |
|---------|----------|-----------|
| `preferencias.json` | `repositorioPreferenciasProvider` | User preferences and settings |
| `benchmark.json` | `repositorioBenchmarkProvider` | Benchmark results per size |
| `historial_conversiones.json` | `repositorioHistorialProvider` | Conversion history (cap 100 entries, complete batches only) |

### Persistence Flow

```
1. App starts → HomeController.build() loads from preferencias.json
2. User changes setting → controller updates state (+ Settings persists immediately)
3. Before processing → PreferencesPersistence saves voice/formats/folders
4. Batch completes without cancel → history appended to historial_conversiones.json
```

## Directory Structure

### Runtime Paths

```
<app_documents>/
├── preferencias.json              # User preferences
├── benchmark.json                 # Benchmark results
├── historial_conversiones.json    # Conversion history
├── archivos/                      # Default input folder
└── audio/                         # Default output folder
    └── _temp/                     # WAVs pending save (> 24 h get cleaned)

<app_support>/
└── modelo/
    ├── onnx/                      # 4 ONNX models + tts.json + unicode_indexer.json
    └── voice_styles/              # F1–F5.json, M1–M5.json
```

### Platform Detection

Decided in `main.dart` (composition root) via `providers.dart`:

```dart
esMovil: Platform.isAndroid || Platform.isIOS,
```

This affects:
- Memory budget (64 MB mobile vs 500 MB desktop)
- UI layout (accordion vs columns, 900 px width threshold)

## Model Configuration

### Supertonic 3 Model

| Property | Value |
|-----------|-------|
| Total size | ~400 MB (15 files) |
| Storage | `<app_support>/modelo/` |
| Resumable | Yes (Dio, Range header) |
| Verification | SHA-256 (ONNX) · size + parsing (JSONs) |

See [supertonic-3-model.md](supertonic-3-model.md) for file details.

## Audio Format Configuration

### WAV

- **Format**: PCM 16-bit
- **Sample rate**: 44100 Hz
- **Channels**: Mono
- **Method**: `wav_io.dart` (pure Dart)

### FFmpeg Formats

| Format | Codec | Method |
|---------|-------|--------|
| MP3 | MPEG Layer III | `ffmpeg_kit` (**default**) |
| FLAC | FLAC lossless | `ffmpeg_kit` |
| OGG | Vorbis | `ffmpeg_kit` |

### Subtype Map

```dart
const subtiposAudio = {
  'wav': 'PCM_16',
  'flac': 'PCM_16',
  'ogg': 'VORBIS',
  'mp3': 'MPEG_LAYER_III',
};
```
