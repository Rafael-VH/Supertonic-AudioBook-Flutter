# Configuration

Technical constants, preferences, and runtime configuration.

## Technical Constants

### Pipeline Config (`shared/data/config.dart`)

| Constant | Value | Description |
|----------|-------|-------------|
| `silenceDurationSecs` | `0.6` | Seconds of silence between fragments |
| `silenceSamples` | `26460` | Samples at 44100 Hz × 0.6s |
| `memoriaSafeMarginBytes` | `524288000` | RAM threshold for desktop (500 MB) |
| `memoriaSafeMarginBytesMovil` | `67108864` | RAM threshold for mobile (64 MB) |
| `subtiposAudio` | Map | Audio subtypes per format |

### Product Defaults (`shared/domain/constants/producto.dart`)

| Constant | Value | Description |
|----------|-------|-------------|
| `defaultVoice` | `'M1'` | Default voice model |
| `defaultLang` | `'es'` | Default synthesis language |
| `defaultTtsSteps` | `5` | Default TTS inference steps (5–12) |
| `defaultSpeed` | `1.1` | Default speech speed (0.7–2.0) |

### Segment Config (`features/convert/domain/use_cases/segmentar_texto.dart`)

| Constant | Value | Description |
|----------|-------|-------------|
| `maxCharsPerSegment` | `1500` | Max characters per TTS fragment |
| `mergeThreshold` | `200` | Paragraphs shorter than this merge with next |

### Supported Formats (`features/convert/domain/use_cases/formato.dart`)

```dart
const formatosNativos = ['wav', 'flac', 'ogg', 'mp3'];
```

## Voices

### Available Voices

| Code | Type |
|------|------|
| `M1`–`M5` | Male voices |
| `F1`–`F5` | Female voices |

### Supported Languages (31 + auto)

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

## User Preferences

### Storage

- **Location**: `<app_documents>/preferencias.json`
- **Format**: JSON key-value pairs
- **Persistence**: `shared_preferences` package

### Preference Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `tema_oscuro` | `bool` | `false` | Dark mode enabled |
| `estilo` | `String` | `'default'` | Visual style variant |
| `idioma` | `String` | `'es'` | UI language |
| `carpeta_in` | `String` | `<base>/archivos` | Input folder path |
| `carpeta_out` | `String` | `<base>/audio` | Output folder path |
| `voz` | `String` | `'M1'` | Selected voice |
| `steps` | `int` | `5` | TTS steps (5–12) |
| `speed` | `double` | `1.1` | Speech speed (0.7–2.0) |
| `lang_voz` | `String` | `'es'` | Voice language |
| `formatos` | `List<String>` | `['wav', 'mp3']` | Output formats |

### Persistence Flow

```
1. App starts → HomeController.build() loads from prefs
2. User changes setting → controller updates state
3. Before processing → _guardarPreferencias() persists all
4. Settings screen → SettingsController._persistir() on each change
```

## Directory Structure

### Runtime Paths

```
<app_documents>/
├── preferencias.json          # User preferences
├── archivos/                  # Default input folder
└── audio/                     # Default output folder

<app_support>/
└── modelo/
    ├── onnx/                  # ONNX model files
    └── voice_styles/          # Voice style JSONs
```

### Platform Detection

Decided in `main.dart` (composition root) via `providers.dart`:

```dart
esMovil: Platform.isAndroid || Platform.isIOS,
```

This affects:
- Memory threshold (64 MB mobile vs 500 MB desktop)
- UI layout (accordion vs columns)

## Model Configuration

### Supertonic 3 Model

| Property | Value |
|----------|-------|
| Size | ~400 MB |
| Storage | `<app_support>/modelo/` |
| Resume | Supported (Dio) |
| Verification | SHA-256 in Isolate |

### Model Files

```
modelo/
├── onnx/
│   └── model.onnx             # TTS model weights
└── voice_styles/
    ├── M1.json                # Male voice 1
    ├── M2.json                # Male voice 2
    ├── ...
    └── F5.json                # Female voice 5
```

## Audio Format Config

### WAV

- **Format**: PCM 16-bit
- **Sample rate**: 44100 Hz
- **Channels**: Mono
- **Method**: `wav_io.dart` (Dart native)

### FFmpeg Formats

| Format | Codec | Method |
|--------|-------|--------|
| MP3 | MPEG Layer III | `ffmpeg_kit` |
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
