# Architecture

Clean Architecture with strict dependency rules across three layers.

## Overview

```
┌─────────────────────────────────────────────────────┐
│                  presentation/                       │
│  controllers (Riverpod)  screens  routing  l10n     │
└──────────────────────────┬──────────────────────────┘
                           │ depends on
                           ▼
┌─────────────────────────────────────────────────────┐
│                    domain/                           │
│  contracts (interfaces)  entities  use_cases         │
│  ⚠ NO dart:io, NO data/, NO UI widgets             │
└──────────────────────────▲──────────────────────────┘
                           │ implements
┌──────────────────────────┴──────────────────────────┐
│                     data/                            │
│  repositories  motor_tts  modelo_manager  config    │
│  ⚠ concrete implementations of domain contracts     │
└─────────────────────────────────────────────────────┘
                           │
                           │ injected in
                           ▼
                  lib/main.dart
              (composition root)
```

## Dependency Rule

**`domain/` never imports `data/` or uses `dart:io`.**

This is the core invariant. Violations are caught by `flutter analyze` and architecture tests.

- `domain/contracts/` defines abstract interfaces (e.g. `MotorTts`, `ExportadorAudio`)
- `data/` provides concrete implementations (e.g. `MotorTtsSupertonic`, `ExportadorAudioFfmpeg`)
- `main.dart` wires them together via Riverpod overrides

### Why this matters

- Domain use cases are testable without platform dependencies
- Swapping implementations (e.g. ffmpeg → native encoder) requires zero domain changes
- `dart:io` (file system, platform detection) stays in `data/` and `presentation/`

## Composition Root (`lib/main.dart`)

The only file that imports both `data/` and `presentation/`. It:

1. Initializes bindings (WidgetsFlutterBinding / FdbBinding)
2. Resolves platform paths (documents, support, model directory)
3. Creates concrete implementations
4. Injects everything into `ProviderScope` overrides

```dart
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

### Provider Injection Map

| Provider | Implementation | Location |
|----------|---------------|----------|
| `repositorioArchivosProvider` | `RepositorioArchivosLocal` | `data/repositories/` |
| `repositorioPreferenciasProvider` | `PreferenciasJsonLocal` | `data/repositories/` |
| `exportadorAudioProvider` | `ExportadorAudioFfmpeg` | `data/repositories/` |
| `reproductorAudioProvider` | `ReproductorJustAudio` | `data/repositories/` |
| `motorTtsProvider` | `MotorTtsSupertonic` | `data/repositories/` |
| `modeloManagerProvider` | `ModeloManager` | `data/modelo/` |
| `configTtsProvider` | Inline record | `main.dart` |
| `carpetaBaseProvider` | Platform path | `main.dart` |

## Domain Layer

### Contracts (`domain/contracts/`)

Abstract interfaces that define what the domain needs, not how it's implemented.

| Contract | Responsibility |
|----------|---------------|
| `MotorTts` | Synthesize text → Float32 audio samples |
| `ExportadorAudio` | Write audio files (WAV/MP3/FLAC/OGG) |
| `RepositorioArchivos` | List/read files, create directories |
| `RepositorioPreferencias` | Load/save key-value preferences |
| `ReproductorAudio` | Play/pause/stop local audio |
| `ModeloGestor` | Download, verify, and manage the TTS model |

### Entities (`domain/entities/`)

Pure data models with no external dependencies.

| Entity | Description |
|--------|-------------|
| `Archivo` | A Markdown file to convert (extends `Equatable`) |
| `LibroGenerado` | A grouped audiobook with format priority |

### Use Cases (`domain/use_cases/`)

Orchestration logic that depends only on contracts and entities.

| Use Case | Purpose |
|----------|---------|
| `ProcesarArchivo` | Convert MD → audio (full pipeline) |
| `LimpiarMarkdown` | Strip Markdown syntax → plain text |
| `SegmentarTexto` | Split text into TTS-ready chunks |
| `SintetizarMuestra` | Generate voice preview |
| `ListarAudiosGenerados` | Group generated audios by book |
| `Formato` | Validate and normalize output formats |

## Data Layer

### Repositories (`data/repositories/`)

Concrete implementations of domain contracts.

| Repository | Implements | Technology |
|-----------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | `shared_preferences` |
| `ExportadorAudioFfmpeg` | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |
| `MotorTtsSupertonic` | `MotorTts` | `flutter_onnxruntime` |

### Model Manager (`data/modelo/`)

`ModeloManager` handles downloading and verifying the Supertonic 3 model (~400 MB):

- Resumable downloads via `Dio`
- SHA-256 integrity verification in Isolate
- Cancel/timeout support
- Stores model in `<app_support>/modelo/onnx/` and `voice_styles/`

### Config (`data/config.dart`)

Technical constants for the TTS pipeline:

```dart
const double silenceDurationSecs = 0.6;    // silence between fragments
const int silenceSamples = 26460;           // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB mobile
```

## Presentation Layer

### State Management (Riverpod)

- **Notifiers** for complex state: `HomeController`, `SettingsController`
- **Providers** for contracts and use cases
- **State classes**: `HomeEstado`, `SettingsEstado` (immutable with `copyWith`)

### Routing (go_router)

Centralized in `lib/presentation/routing/app_router.dart`:

```dart
abstract final class Rutas {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const home = '/home';
  static const modelo = '/modelo';
  static const settings = '/settings';
  static const seleccion = '/seleccion';
  static const biblioteca = '/biblioteca';
}
```

See [routing.md](routing.md) for navigation flow details.

### Theme (`presentation/theme/`)

- `AppTheme` with `ThemeMode` (dark/light) and `AppEstilo` variants
- Palette system (`Paleta`) for consistent colors
- Applied via `construirTema()` in `app.dart`

### Internationalization (`presentation/l10n/`)

- ARB files: `app_es.arb`, `app_en.arb`
- Generated via `flutter gen-l10n`
- Never edit `.dart` generated files directly

## Testing Strategy

### Architecture Tests

Verify the dependency rule: `domain/` never imports `data/` or `dart:io`.

### Unit Tests

- **Domain use cases**: Pure logic, no mocks needed
- **Controllers**: Mocked contracts via `mocktail`

### Widget Tests

- **Screens**: Full widget trees with mocked providers
- **Routing**: Navigation and redirect logic

### Integration Points

- `ProcesarArchivo` has integration tests with real export pipeline
- `ExportadorSelectivo` pattern for testing format export independently

See [testing.md](testing.md) for full metrics and conventions.

## Key Design Decisions

### 1. Composition Root Pattern

All dependency injection happens in `main.dart`. No service locator, no abstract factories — just Riverpod overrides.

**Tradeoff**: More boilerplate in `main.dart`, but explicit and testable.

### 2. Domain-Driven File Naming

Entities and use cases use Spanish names matching the original Python implementation:
- `Archivo` (not `MarkdownFile`)
- `ProcesarArchivo` (not `ProcessFile`)
- `HomeEstado` (not `HomeState`)

**Rationale**: Consistency with the Python codebase that preceded this Flutter rewrite.

### 3. Memory Budget for Mobile

Mobile devices get a lower memory threshold (64 MB vs 500 MB desktop) to prevent OOM:

```dart
if (memoriaAcumulada > presupuesto) {
  await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
  fragmentos.clear();
}
```

### 4. Atomic Publication

Audio files are published via rename (atomic on most filesystems). On cancel, existing files are preserved — never replaced with truncated output.
