# Architecture

Clean Architecture with feature-based modules and a shared infrastructure layer (`shared/`).

## Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                          features/                                    │
│                                                                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐         │
│  │  convert/      │  │  biblioteca/   │  │  modelo/       │  ...   │
│  │  domain ← data │  │  domain        │  │  domain ← data │         │
│  │  presentation  │  │  presentation  │  │  presentation  │         │
│  └───────┬────────┘  └───────┬────────┘  └───────┬────────┘         │
│          │ depends on        │ depends on         │ depends on       │
│          ▼                   ▼                    ▼                  │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     shared/                                   │   │
│  │  domain/contracts/  entities  constants                       │   │
│  │  data/config.dart   repositories (archivos, prefs, player)    │   │
│  │  ⚠ NO dart:io in domain/                                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ injected in
                                     ▼
                          lib/main.dart + providers.dart
                        (composition root + DI)
```

**Features**: `audio_manager`, `benchmark`, `biblioteca`, `convert`, `dashboard`, `editor_metadata`, `home`, `modelo`, `onboarding`, `settings`, `splash`.

## Dependency Rule

**`domain/` never imports `data/` and never uses `dart:io`.**

This is the central invariant. Violations are caught by `flutter analyze` and architecture tests.

- Each feature owns its contracts in `features/X/domain/contracts/` (e.g. `MotorTts`, `ExportadorAudio`)
- `shared/domain/contracts/` defines contracts used by multiple features (e.g. `RepositorioArchivos`, `RepositorioPreferencias`)
- `features/X/data/` provides concrete implementations for the feature
- `shared/data/` provides implementations of shared contracts
- `main.dart` wires everything via Riverpod overrides in `providers.dart`

### Why it matters

- Domain use cases are testable without platform dependencies
- Swapping implementations (e.g. ffmpeg → native encoder) requires zero domain changes
- `dart:io` (file system, platform detection) lives in `data/` and `presentation/`
- Each feature is self-contained: it can change without affecting other features

## Composition Root (`lib/main.dart` + `providers.dart`)

`main.dart` is the only file that imports concrete `data/` implementations. It:

1. Initializes bindings (WidgetsFlutterBinding / FdbBinding depending on release mode)
2. Cleans orphaned WAVs from previous runs (`LimpiarTemporales`, > 24 h)
3. Resolves platform paths (documents, support, model)
4. Creates concrete implementations
5. Injects everything into `ProviderScope` overrides via `providers.dart`

```dart
// main.dart
ProviderScope(
  overrides: [
    repositorioArchivosProvider.overrideWithValue(RepositorioArchivosLocal()),
    motorTtsProvider.overrideWith((ref) => MotorTtsSupertonic(...)),
    exportadorAudioProvider.overrideWithValue(ExportadorAudioFfmpeg()),
    // ... etc
  ],
  child: const App(),
)
```

`providers.dart` declares `domain/` contracts as Riverpod providers that **fail fast when used without injection**. It is the single entry point to concrete implementations.

### Provider Injection Map

| Provider | Implementation | Location |
|----------|---------------|-----------|
| `repositorioArchivosProvider` | `RepositorioArchivosLocal` | `shared/data/repositories/` |
| `repositorioPreferenciasProvider` | `PreferenciasJsonLocal` → `preferencias.json` | `shared/data/repositories/` |
| `repositorioBenchmarkProvider` | `PreferenciasJsonLocal` → `benchmark.json` | `shared/data/repositories/` |
| `repositorioHistorialProvider` | `PreferenciasJsonLocal` → `historial_conversiones.json` | `shared/data/repositories/` |
| `exportadorAudioProvider` | `ExportadorAudioFfmpeg` | `features/convert/data/repositories/` |
| `fileSystemProvider` | `FileSystemLocal` | `features/convert/data/repositories/` |
| `reproductorAudioProvider` | `ReproductorJustAudio` | `shared/data/repositories/` |
| `motorTtsProvider` | `MotorTtsSupertonic` | `features/convert/data/repositories/` |
| `modeloManagerProvider` | `ModeloManager` | `features/modelo/data/repositories/` |
| `editorMetadataProvider` | `EditorMetadataId3Codec` | `features/editor_metadata/data/repositories/` |
| `domainLoggerProvider` | `PrintLogger` | `shared/data/repositories/` |
| `configTtsProvider` | `TtsConfig` record | `providers.dart` |
| `carpetaBaseProvider` | Platform path | `main.dart` |

The three JSON repositories (`preferencias`, `benchmark`, `historial_conversiones`) are separate instances of the same `PreferenciasJsonLocal` class.

## Domain Layer

### Shared Contracts (`shared/domain/contracts/`)

Abstract interfaces used by multiple features.

| Contract | Responsibility |
|----------|----------------|
| `RepositorioArchivos` | List/read/move/delete files, create directories |
| `RepositorioPreferencias` | Load/save key-value preferences (JSON) |
| `ReproductorAudio` | Play/pause/resume/stop local audio |
| `DomainLogger` | Abstract logging (implemented by `PrintLogger`) |

### Per-Feature Contracts (`features/X/domain/contracts/`)

| Contract | Feature | Responsibility |
|----------|---------|----------------|
| `MotorTts` | convert | Synthesize text → Float32 audio samples |
| `ExportadorAudio` | convert | Write/convert audio files (WAV/MP3/FLAC/OGG) |
| `FileSystemContract` | convert | Path operations (parentOf, fileName, separator) |
| `ModeloGestor` | modelo | Download, verify and manage the TTS model |
| `EditorMetadata` | editor_metadata | Read/write ID3 tags of MP3 files |

### Entities

| Entity | Feature | Description |
|--------|---------|-------------|
| `Archivo` | shared | A Markdown file to convert (extends `Equatable`) |
| `VoiceConfig` | shared | Voice + steps + speed + synthesis language |
| `AppPreferences` | shared | Typed app preferences |
| `LibroGenerado` | biblioteca | A grouped audiobook with format priority |
| `MetadatosMp3` | editor_metadata | ID3 tags of an MP3 file |
| `AudioPendiente` | audio_manager | Temp WAV awaiting save/cancel |
| `BenchmarkResult` | benchmark | Benchmark results per text size |
| `ConversionEntry` | benchmark | Metrics of one conversion (chars, segments, duration) |

### Use Cases

| Use Case | Feature | Purpose |
|----------|---------|---------|
| `ProcesarArchivo` | convert | Convert MD → temp WAV in `_temp/` |
| `LimpiarMarkdown` | convert | Strip Markdown syntax → plain text |
| `SegmentarTexto` | convert | Split text into TTS-ready chunks |
| `SintetizarMuestra` | convert | Generate voice preview |
| `Formato` | convert | Validate and normalize output formats |
| `ListarAudiosGenerados` | biblioteca | Group generated audios by book |
| `EditarMetadataMp3` | editor_metadata | Edit ID3 tags of MP3 files |
| `GuardarAudio` | audio_manager | Move temp WAV → final destination (`(N)` suffix on conflict) |
| `LimpiarTemporales` | audio_manager | Delete temp WAVs older than 24 h |
| `EstimarMemoria` | audio_manager | Estimate batch memory budget before processing |
| `RunBenchmark` | benchmark | Run benchmark at a given text size |
| `EstimarTiempo` | benchmark | Estimate conversion time from benchmark data |

## Data Layer

### Shared Repositories (`shared/data/repositories/`)

| Repository | Implements | Technology |
|------------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | Local JSON file |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |
| `PrintLogger` | `DomainLogger` | Console |

### Per-Feature Repositories

| Repository | Feature | Implements | Technology |
|------------|---------|-----------|------------|
| `ExportadorAudioFfmpeg` | convert | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `MotorTtsSupertonic` | convert | `MotorTts` | `flutter_onnxruntime` |
| `FileSystemLocal` | convert | `FileSystemContract` | `dart:io` |
| `ModeloManager` | modelo | `ModeloGestor` | `Dio` + `crypto` |
| `EditorMetadataId3Codec` | editor_metadata | `EditorMetadata` | `id3_codec` |

### Model Manager (`features/modelo/data/repositories/modelo_manager.dart`)

`ModeloManager` handles download and verification of the Supertonic 3 model (~400 MB, 15 files):

- Resumable downloads with `Dio` (`Range` header, append to a `.part` file)
- SHA-256 verification for ONNX files (in an Isolate); exact size + JSON parsing for configs and voice styles
- Cancellation/timeout support
- Stores the model in `<app_support>/modelo/onnx/` and `voice_styles/`

### Configuration (`shared/data/config.dart`)

Technical constants of the TTS pipeline:

```dart
const double silenceDurationSecs = 0.6;            // silence between fragments
const int silenceSamples = 26460;                  // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB mobile
```

## Presentation Layer

### Screens per Feature (`features/X/presentation/screens/`)

| Screen | Feature | Route |
|----------|---------|------|
| SplashScreen | splash | `/splash` |
| OnboardingScreen | onboarding | `/onboarding` |
| DashboardScreen | dashboard | `/dashboard` (NavigationBar shell) |
| HomeScreen (hub) | home | dashboard tab 0 |
| ConvertScreen | convert | `/home` |
| ModeloScreen | modelo | `/modelo` |
| BibliotecaScreen | biblioteca | `/biblioteca` (embedded tab 1) |
| SettingsScreen | settings | `/settings` (embedded tab 2) |
| MetadataEditorScreen | editor_metadata | `/editor-metadata` |
| BenchmarkScreen | benchmark | `/benchmark` |
| AudioManagerScreen | audio_manager | `/audio-manager` |

See [screens.md](screens.md) for details on each screen.

### Controllers per Feature (`features/X/presentation/controllers/`)

| Controller | Feature | Responsibility |
|-----------|---------|----------------|
| `HomeController` | convert | Conversion state (`HomeEstado`), orchestrates the batch |
| `SettingsController` | settings | App preferences |
| `BibliotecaController` | biblioteca | Library state and playback |
| `ModeloController` | modelo | Model download state |
| `MetadataEditorController` | editor_metadata | Metadata editor state |
| `BenchmarkController` | benchmark | Benchmark rows and history |
| `AudioManagerController` | audio_manager | Pending audios (save/cancel) |

### State Management (Riverpod)

- **Notifiers** for complex state: `HomeController`, `BibliotecaController`, etc.
- **Providers** for contracts and use cases (defined in `providers.dart`)
- **State classes**: `HomeEstado`, `BibliotecaEstado`, etc. (immutable with `copyWith`)

### Routing (go_router)

Centralized in `lib/presentation/routing/app_router.dart`:

```dart
abstract final class Rutas {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const home = '/home';           // → ConvertScreen
  static const modelo = '/modelo';
  static const settings = '/settings';
  static const biblioteca = '/biblioteca';
  static const editorMetadata = '/editor-metadata';
  static const benchmark = '/benchmark';
  static const audioManager = '/audio-manager';
}
```

Active gates: splash decides onboarding vs dashboard; `/home` without a model redirects to `/modelo`. See [routing.md](routing.md).

### Theme (`presentation/theme/`)

- `AppTheme` with `ThemeMode` (dark/light) and `AppEstilo` variants (material/neumorphism/skeuomorphism)
- Palette system (`Paleta`) for consistent colors
- Applied via `construirTema()` in `app.dart`

### Internationalization (`presentation/l10n/`)

- ARB files: `app_es.arb`, `app_en.arb` (template: `app_en.arb`)
- Generated with `flutter gen-l10n` (configured in `l10n.yaml`)
- Never edit the generated `.dart` files directly

## Testing Strategy

### Architecture Tests

Verify the dependency rule: `domain/` never imports `data/` nor `dart:io`.

### Unit Tests

- **Domain use cases**: pure logic, no mocks
- **Controllers**: contracts mocked with `mocktail`

### Widget Tests

- **Screens**: full widget trees with mocked providers
- **Routing**: navigation and redirect logic

### Test Structure

Mirrors `lib/` feature by feature:

```
test/
├── core/                        # WAV I/O, natural sort
├── shared/                      # Shared repositories and entities
├── features/                    # One directory per feature
│   ├── audio_manager/           # Entities and use cases (save, cleanup)
│   ├── benchmark/               # Entities, use cases, controller
│   ├── biblioteca/              # List audios use case
│   ├── convert/                 # Data, use cases, widgets
│   ├── editor_metadata/         # ID3 codec, entity, controller, screen
│   └── modelo/                  # ModeloManager
├── presentation/                # Shared controllers, routing, screens, theme
└── support/                     # Test helpers
```

See [testing.md](testing.md) for full metrics and conventions.

## Key Design Decisions

### 1. Composition Root Pattern

All dependency injection happens in `main.dart`. No service locator, no abstract factories — just Riverpod overrides.

**Tradeoff**: More boilerplate in `main.dart`, but explicit and testable.

### 2. Domain-Driven Naming

Entities and use cases use Spanish names matching the original Python implementation:
- `Archivo` (not `MarkdownFile`)
- `ProcesarArchivo` (not `ProcessFile`)
- `HomeEstado` (not `HomeState`)

**Reason**: Consistency with the Python codebase that preceded this Flutter rewrite.

### 3. Mobile Memory Budget

Mobile devices get a lower memory threshold (64 MB vs 500 MB desktop) to prevent OOM:

```dart
if (memoriaAcumulada > presupuesto) {
  await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
  fragmentos.clear();
}
```

Additionally, before starting a batch the required memory is estimated: if it exceeds 70 % of available RAM, a warning dialog is shown.

### 4. Deferred Publishing (audio-manager)

Synthesis **never writes to the final path**: it produces temp WAVs in `<output>/_temp/` and the user publishes them from the pending-audios screen (atomic rename). On cancel, temps are deleted and existing files stay untouched.
