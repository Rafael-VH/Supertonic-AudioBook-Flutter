# Testing

Test structure, conventions, and metrics.

## Quick Start

```bash
flutter test              # Run all tests
flutter test --coverage   # Generate coverage report
flutter analyze lib       # Static analysis
```

## Metrics

| Metric | Value |
|--------|-------|
| Total tests | 228 |
| Passed | 228 |
| Skipped | 4 (FFmpeg-dependent) |
| Coverage (active change) | ≥ 94% |
| Analysis | 0 warnings |

## Test Structure

```
test/
├── core/
│   ├── audio/
│   │   └── wav_io_test.dart              # WAV PCM16 writing
│   └── utils/
│       └── natural_sort_test.dart         # Natural sort ordering
│
├── data/
│   ├── modelo/
│   │   └── modelo_manager_test.dart       # Model download/verify
│   └── repositories/
│       ├── exportador_audio_ffmpeg_test.dart  # FFmpeg export
│       ├── repositorio_archivos_test.dart     # File operations
│       └── repositorio_preferencias_test.dart # Preferences
│
├── domain/
│   └── use_cases/
│       ├── procesar_archivo_test.dart         # Process file (unit)
│       ├── procesar_archivo_integration_test.dart  # Process file (integration)
│       ├── limpiar_markdown_test.dart         # Markdown cleaning
│       ├── segmentar_texto_test.dart          # Text segmentation
│       ├── sintetizar_muestra_test.dart       # Voice preview
│       ├── listar_audios_generados_test.dart  # Audio listing
│       └── formato_test.dart                  # Format validation
│
├── features/
│   └── editor_metadata/
│       ├── data/repositories/
│       │   └── editor_metadata_id3_codec_test.dart  # ID3 codec
│       ├── domain/
│       │   ├── contracts/
│       │   │   └── editor_metadata_test.dart         # EditorMetadata contract
│       │   ├── entities/
│       │   │   └── metadatos_mp3_test.dart           # MetadatosMp3 entity
│       │   └── use_cases/
│       │       └── editar_metadata_mp3_test.dart     # Edit metadata
│       └── presentation/
│           ├── controllers/
│           │   └── metadata_editor_controller_test.dart  # Controller
│           └── screens/
│               └── metadata_editor_screen_test.dart      # UI
│
└── presentation/
    ├── controllers/
    │   ├── home_controller_test.dart       # Home state management
    │   ├── biblioteca_controller_test.dart # Library state
    │   ├── modelo_controller_test.dart     # Model screen state
    │   └── providers_test.dart             # Provider overrides
    │
    ├── routing/
    │   └── app_router_test.dart            # Navigation/redirects
    │
    ├── screens/
    │   ├── convert_screen_test.dart        # Convert UI
    │   ├── home_movil_diag_test.dart       # Convert mobile layout
    │   ├── settings_screen_test.dart       # Settings UI
    │   ├── dashboard_screen_test.dart      # Dashboard UI
    │   ├── modelo_screen_test.dart         # Model screen UI
    │   └── biblioteca/
    │       └── biblioteca_screen_test.dart # Library UI
    │
    └── theme/
        └── paleta_test.dart                # Color palette
```

## Test Types

### Unit Tests

Pure logic tests with no Flutter dependencies.

```dart
test('limpiarMarkdown strips headings', () {
  expect(limpiarMarkdown('# Hello'), 'Hello');
});

test('segmentarTexto respects maxCharsPerSegment', () {
  final segments = segmentarTexto('A' * 2000);
  expect(segments.every((s) => s.length <= 1500), true);
});
```

### Integration Tests

`ProcesarArchivo` integration test verifies the full pipeline:

```dart
test('procesar genera WAV y MP3', () async {
  final resultado = await useCase.procesar(
    archivo,
    rutaBase,
    steps: 5,
    speed: 1.0,
    formatos: ['wav', 'mp3'],
  );
  expect(resultado, ResultadoProceso.ok);
  expect(File('$rutaBase.wav').existsSync(), true);
  expect(File('$rutaBase.mp3').existsSync(), true);
});
```

### Widget Tests

Full screen tests with mocked providers:

```dart
testWidgets('ConvertScreen shows folder picker', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* mocked providers */],
      child: const MaterialApp(home: ConvertScreen()),
    ),
  );
  expect(find.text('Select folder'), findsOneWidget);
});
```

### Architecture Tests

Verify dependency rules:

```dart
test('domain does not import data', () {
  // Verify no imports from data/ in domain/ files
  // within each feature (features/X/domain/ doesn't import features/X/data/)
  // and shared/domain/ doesn't import shared/data/
});
```

## Conventions

### Mocking

Use `mocktail` for all mocks:

```dart
class MockMotorTts extends Mock implements MotorTts {}
class MockRepositorioArchivos extends Mock implements RepositorioArchivos {}
```

### Provider Overrides

Always override providers in widget tests:

```dart
ProviderScope(
  overrides: [
    repositorioArchivosProvider.overrideWithValue(mockRepo),
    motorTtsProvider.overrideWithValue(mockMotor),
    carpetaBaseProvider.overrideWithValue('/test/path'),
  ],
  child: const MaterialApp(home: ConvertScreen()),
)
```

### Test Naming

```dart
group('ProcesarArchivo', () {
  test('procesar returns omitido for empty file', () async { ... });
  test('procesar returns error for unreadable file', () async { ... });
  test('procesar generates WAV on success', () async { ... });
});
```

### Coverage Targets

| Layer | Target |
|-------|--------|
| Domain use cases | ≥ 95% |
| Controllers | ≥ 90% |
| Screens | ≥ 85% |
| Overall | ≥ 90% |

## Skipped Tests

4 tests skipped due to FFmpeg dependency:

```dart
// These tests require ffmpeg_kit native binary
skip: 'Requires FFmpeg native binary',
```

These are integration-level tests that can only run on real devices with FFmpeg installed.

## Running Specific Tests

```bash
# Run a single test file
flutter test test/domain/use_cases/limpiar_markdown_test.dart

# Run a specific test
flutter test --name "limpiarMarkdown strips headings"

# Run with coverage for specific files
flutter test --coverage test/domain/
```

## CI Integration

```yaml
# GitHub Actions example
- name: Test
  run: flutter test

- name: Analyze
  run: flutter analyze lib

- name: Coverage
  run: flutter test --coverage
```
