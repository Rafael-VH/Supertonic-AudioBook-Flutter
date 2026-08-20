# Testing

Test structure, conventions and metrics.

## Quick Start

```bash
flutter test              # Run all tests
flutter test --coverage   # Generate coverage report
flutter analyze lib       # Static analysis
```

## Metrics

| Metric | Value |
|---------|-------|
| Test files | 45 |
| Test cases | 369 |
| Skips | Integration tests requiring native FFmpeg |
| Analysis | 0 warnings |

## Test Structure

Mirrors `lib/` feature by feature:

```
test/
├── core/
│   ├── audio/
│   │   └── wav_io_test.dart               # PCM16 WAV writing
│   └── utils/
│       └── natural_sort_test.dart         # Natural sorting
│
├── shared/
│   ├── data/repositories/                 # Files, JSON preferences
│   └── domain/entities/                   # Shared entities
│
├── features/
│   ├── audio_manager/
│   │   ├── domain/entities/               # AudioPendiente
│   │   └── domain/use_cases/              # GuardarAudio, LimpiarTemporales
│   ├── benchmark/
│   │   ├── domain/{entities,use_cases}/   # BenchmarkResult, RunBenchmark, EstimarTiempo
│   │   └── presentation/controllers/      # BenchmarkController
│   ├── biblioteca/
│   │   └── domain/use_cases/              # ListarAudiosGenerados
│   ├── convert/
│   │   ├── data/repositories/             # FFmpeg exporter, TTS engine
│   │   ├── domain/use_cases/              # ProcesarArchivo (unit + integration), etc.
│   │   └── presentation/widgets/          # Log content, log view
│   ├── editor_metadata/
│   │   ├── data/repositories/             # ID3 codec
│   │   ├── domain/{contracts,entities,use_cases}/
│   │   └── presentation/{controllers,screens}/
│   └── modelo/
│       └── data/repositories/             # ModeloManager (download/verification)
│
├── presentation/
│   ├── controllers/                       # HomeController, BibliotecaController,
│   │                                      # ModeloController, providers
│   ├── routing/app_router_test.dart       # Navigation and redirects
│   ├── screens/                           # Convert, Settings, Dashboard, Model,
│   │   └── biblioteca/                    # Benchmark, AudioManager, Library
│   └── theme/paleta_test.dart             # Color palette
│
└── support/                               # Test helpers
```

## Test Types

### Unit Tests

Pure logic tests without Flutter dependencies.

```dart
test('limpiarMarkdown removes headings', () {
  expect(limpiarMarkdown('# Hello'), 'Hello');
});

test('segmentarTexto respects maxCharsPerSegment', () {
  final segments = segmentarTexto('A' * 2000);
  expect(segments.every((s) => s.length <= 1500), true);
});
```

### Integration Tests

The `ProcesarArchivo` integration test verifies the full pipeline up to the temp WAV:

```dart
test('procesar generates temp WAV in _temp/', () async {
  final resultado = await useCase.procesar(archivo, rutaBase, ...);
  expect(resultado.estado, ResultadoProceso.ok);
  expect(File(resultado.tempPath!).existsSync(), true);
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
  // features/X/domain/ does not import features/X/data/
  // shared/domain/ does not import shared/data/
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
  test('procesar returns omitted for empty file', () async { ... });
  test('procesar returns error for unreadable file', () async { ... });
  test('procesar generates WAV on success', () async { ... });
});
```

## FFmpeg Tests

Some export tests require the native `ffmpeg_kit` binary and are marked with skip:

```dart
skip: 'Requires native FFmpeg binary',
```

These are integration-level tests that can only run on real devices.

## Running Specific Tests

```bash
# Single file
flutter test test/features/convert/domain/use_cases/limpiar_markdown_test.dart

# Specific test
flutter test --name "limpiarMarkdown removes headings"

# With coverage
flutter test --coverage test/features/
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
