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
│  │  domain/contracts/  entities  use_cases  constants            │   │
│  │  data/config.dart   repositories (archivos, prefs, player)   │   │
│  │  ⚠ NO dart:io in domain/                                     │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ injected in
                                     ▼
                          lib/main.dart + providers.dart
                        (composition root + DI)
```

## Dependency Rule

**`domain/` never imports `data/` or uses `dart:io`.**

This is the core invariant. Violations are caught by `flutter analyze` and architecture tests.

- Each feature has its own contracts in `features/X/domain/contracts/` (e.g. `MotorTts`, `ExportadorAudio`)
- `shared/domain/contracts/` defines contracts used by multiple features (e.g. `RepositorioArchivos`, `RepositorioPreferencias`)
- `features/X/data/` provides concrete implementations for the feature
- `shared/data/` provides implementations for shared contracts
- `main.dart` wires them together via Riverpod overrides in `providers.dart`

### Why this matters

- Domain use cases are testable without platform dependencies
- Swapping implementations (e.g. ffmpeg → native encoder) requires zero domain changes
- `dart:io` (file system, platform detection) stays in `data/` and `presentation/`
- Each feature is self-contained: can be modified without affecting other features

## Composition Root (`lib/main.dart` + `providers.dart`)

`main.dart` is the only file that imports concrete implementations from `data/`. It:

1. Initializes bindings (WidgetsFlutterBinding / FdbBinding)
2. Resolves platform paths (documents, support, model directory)
3. Creates concrete implementations
4. Injects everything into `ProviderScope` overrides via `providers.dart`

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

`providers.dart` defines domain contracts as Riverpod providers. It's the single entry point to concrete implementations.

### Provider Injection Map

| Provider | Implementation | Location |
|----------|---------------|----------|
| `repositorioArchivosProvider` | `RepositorioArchivosLocal` | `shared/data/repositories/` |
| `repositorioPreferenciasProvider` | `PreferenciasJsonLocal` | `shared/data/repositories/` |
| `exportadorAudioProvider` | `ExportadorAudioFfmpeg` | `features/convert/data/repositories/` |
| `reproductorAudioProvider` | `ReproductorJustAudio` | `shared/data/repositories/` |
| `motorTtsProvider` | `MotorTtsSupertonic` | `features/convert/data/repositories/` |
| `modeloManagerProvider` | `ModeloManager` | `features/modelo/data/repositories/` |
| `editorMetadataProvider` | `EditorMetadataId3Codec` | `features/editor_metadata/data/repositories/` |
| `configTtsProvider` | Inline record | `providers.dart` |
| `carpetaBaseProvider` | Platform path | `main.dart` |

## Domain Layer

### Shared Contracts (`shared/domain/contracts/`)

Abstract interfaces used by multiple features.

| Contract | Responsibility |
|----------|---------------|
| `RepositorioArchivos` | List/read files, create directories |
| `RepositorioPreferencias` | Load/save key-value preferences |
| `ReproductorAudio` | Play/pause/stop local audio |

### Feature Contracts (`features/X/domain/contracts/`)

Feature-specific interfaces.

| Contract | Feature | Responsibility |
|----------|---------|---------------|
| `MotorTts` | convert | Synthesize text → Float32 audio samples |
| `ExportadorAudio` | convert | Write audio files (WAV/MP3/FLAC/OGG) |
| `ModeloGestor` | modelo | Download, verify, and manage the TTS model |
| `EditorMetadata` | editor_metadata | Edit ID3 metadata of MP3 files |

### Entities

| Entity | Feature | Description |
|--------|---------|-------------|
| `Archivo` | convert | A Markdown file to convert (extends `Equatable`) |
| `LibroGenerado` | biblioteca | A grouped audiobook with format priority |
| `MetadatosMp3` | editor_metadata | ID3 metadata of an MP3 file |

### Use Cases

| Use Case | Feature | Purpose |
|----------|---------|---------|
| `ProcesarArchivo` | convert | Convert MD → audio (full pipeline) |
| `LimpiarMarkdown` | convert | Strip Markdown syntax → plain text |
| `SegmentarTexto` | convert | Split text into TTS-ready chunks |
| `SintetizarMuestra` | convert | Generate voice preview |
| `Formato` | convert | Validate and normalize output formats |
| `ListarAudiosGenerados` | biblioteca | Group generated audios by book |
| `EditarMetadataMp3` | editor_metadata | Edit ID3 metadata in MP3 files |

## Data Layer

### Shared Repositories (`shared/data/repositories/`)

Concrete implementations of shared contracts.

| Repository | Implements | Technology |
|-----------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | `shared_preferences` |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |

### Feature Repositories

| Repository | Feature | Implements | Technology |
|-----------|---------|-----------|------------|
| `ExportadorAudioFfmpeg` | convert | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `MotorTtsSupertonic` | convert | `MotorTts` | `flutter_onnxruntime` |
| `ModeloManager` | modelo | `ModeloGestor` | `Dio` |
| `EditorMetadataId3Codec` | editor_metadata | `EditorMetadata` | ID3 codec |

### Model Manager (`features/modelo/data/repositories/modelo_manager.dart`)

`ModeloManager` handles downloading and verifying the Supertonic 3 model (~400 MB):

- Resumable downloads via `Dio`
- SHA-256 integrity verification in Isolate
- Cancel/timeout support
- Stores model in `<app_support>/modelo/onnx/` and `voice_styles/`

### Config (`shared/data/config.dart`)

Technical constants for the TTS pipeline:

```dart
const double silenceDurationSecs = 0.6;    // silence between fragments
const int silenceSamples = 26460;           // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB mobile
```

## Presentation Layer

### Screens per Feature (`features/X/presentation/screens/`)

Each feature has its own screens. The main conversion screen is `ConvertScreen` (previously `HomeScreen`):

| Screen | Feature | File |
|--------|---------|------|
| SplashScreen | splash | `features/splash/presentation/screens/splash_screen.dart` |
| OnboardingScreen | onboarding | `features/onboarding/presentation/screens/onboarding_screen.dart` |
| DashboardScreen | dashboard | `features/dashboard/presentation/screens/dashboard_screen.dart` |
| ConvertScreen | convert | `features/convert/presentation/screens/convert_screen.dart` |
| ModeloScreen | modelo | `features/modelo/presentation/screens/modelo_screen.dart` |
| BibliotecaScreen | biblioteca | `features/biblioteca/presentation/screens/biblioteca_screen.dart` |
| SettingsScreen | settings | `features/settings/presentation/screens/settings_screen.dart` |
| MetadataEditorScreen | editor_metadata | `features/editor_metadata/presentation/screens/metadata_editor_screen.dart` |

### Controllers per Feature (`features/X/presentation/controllers/`)

| Controller | Feature | Responsibility |
|-----------|---------|---------------|
| `HomeController` | convert | Conversion state (HomeEstado) |
| `SettingsController` | settings | App preferences |
| `BibliotecaController` | biblioteca | Library state |
| `ModeloController` | modelo | Model download state |
| `MetadataEditorController` | editor_metadata | Metadata editor state |

### State Management (Riverpod)

- **Notifiers** for complex state: `HomeController`, `SettingsController`
- **Providers** for contracts and use cases (defined in `providers.dart`)
- **State classes**: `HomeEstado`, `SettingsEstado` (immutable with `copyWith`)

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

### Test Structure

```
test/
├── core/                          # WAV I/O, natural sort
├── data/                          # Shared repositories
├── domain/                        # Shared use cases
├── features/editor_metadata/      # editor_metadata feature tests
│   ├── data/repositories/
│   ├── domain/{contracts,entities,use_cases}/
│   └── presentation/{controllers,screens}/
├── presentation/
│   ├── controllers/               # Controllers (home, biblioteca, modelo, providers)
│   ├── screens/                   # Screen widgets
│   ├── routing/                   # Navigation and redirects
│   └── theme/                     # Palette and visual styles
└── support/                       # Test helpers
```

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
