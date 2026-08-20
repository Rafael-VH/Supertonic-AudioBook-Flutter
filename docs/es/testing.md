# Testing

Estructura de tests, convenciones y métricas.

## Inicio Rápido

```bash
flutter test              # Ejecutar todos los tests
flutter test --coverage   # Generar reporte de cobertura
flutter analyze lib       # Análisis estático
```

## Métricas

| Métrica | Valor |
|---------|-------|
| Archivos de test | 45 |
| Casos de test | 369 |
| Skips | Tests de integración que requieren FFmpeg nativo |
| Análisis | 0 warnings |

## Estructura de Tests

Espeja `lib/` feature por feature:

```
test/
├── core/
│   ├── audio/
│   │   └── wav_io_test.dart               # Escritura WAV PCM16
│   └── utils/
│       └── natural_sort_test.dart         # Ordenamiento natural
│
├── shared/
│   ├── data/repositories/                 # Archivos, preferencias JSON
│   └── domain/entities/                   # Entidades compartidas
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
│   │   ├── data/repositories/             # Exportador FFmpeg, motor TTS
│   │   ├── domain/use_cases/              # ProcesarArchivo (unit + integración), etc.
│   │   └── presentation/widgets/          # Registro, vista log
│   ├── editor_metadata/
│   │   ├── data/repositories/             # Codec ID3
│   │   ├── domain/{contracts,entities,use_cases}/
│   │   └── presentation/{controllers,screens}/
│   └── modelo/
│       └── data/repositories/             # ModeloManager (descarga/verificación)
│
├── presentation/
│   ├── controllers/                       # HomeController, BibliotecaController,
│   │                                      # ModeloController, providers
│   ├── routing/app_router_test.dart       # Navegación y redirects
│   ├── screens/                           # Convert, Settings, Dashboard, Modelo,
│   │   └── biblioteca/                    # Benchmark, AudioManager, Biblioteca
│   └── theme/paleta_test.dart             # Paleta de colores
│
└── support/                               # Helpers de test
```

## Tipos de Tests

### Tests Unitarios

Tests de lógica pura sin dependencias de Flutter.

```dart
test('limpiarMarkdown elimina encabezados', () {
  expect(limpiarMarkdown('# Hello'), 'Hello');
});

test('segmentarTexto respeta maxCharsPerSegment', () {
  final segments = segmentarTexto('A' * 2000);
  expect(segments.every((s) => s.length <= 1500), true);
});
```

### Tests de Integración

El test de integración de `ProcesarArchivo` verifica el pipeline completo hasta el WAV temporal:

```dart
test('procesar genera WAV temporal en _temp/', () async {
  final resultado = await useCase.procesar(archivo, rutaBase, ...);
  expect(resultado.estado, ResultadoProceso.ok);
  expect(File(resultado.tempPath!).existsSync(), true);
});
```

### Tests de Widget

Tests completos de pantalla con providers mockeados:

```dart
testWidgets('ConvertScreen muestra selector de carpeta', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* providers mockeados */],
      child: const MaterialApp(home: ConvertScreen()),
    ),
  );
  expect(find.text('Select folder'), findsOneWidget);
});
```

### Tests de Arquitectura

Verifican reglas de dependencia:

```dart
test('domain no importa data', () {
  // features/X/domain/ no importa features/X/data/
  // shared/domain/ no importa shared/data/
});
```

## Convenciones

### Mocking

Usar `mocktail` para todos los mocks:

```dart
class MockMotorTts extends Mock implements MotorTts {}
class MockRepositorioArchivos extends Mock implements RepositorioArchivos {}
```

### Overrides de Providers

Siempre sobreescribir providers en tests de widget:

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

### Nombre de Tests

```dart
group('ProcesarArchivo', () {
  test('procesar devuelve omitido para archivo vacío', () async { ... });
  test('procesar devuelve error para archivo ilegible', () async { ... });
  test('procesar genera WAV en éxito', () async { ... });
});
```

## Tests con FFmpeg

Algunos tests de exportación requieren el binario nativo de `ffmpeg_kit` y se marcan con skip:

```dart
skip: 'Requiere binario nativo de FFmpeg',
```

Son tests de nivel de integración que solo pueden ejecutarse en dispositivos reales.

## Ejecutar Tests Específicos

```bash
# Un solo archivo
flutter test test/features/convert/domain/use_cases/limpiar_markdown_test.dart

# Un test específico
flutter test --name "limpiarMarkdown elimina encabezados"

# Con cobertura
flutter test --coverage test/features/
```

## Integración CI

```yaml
# Ejemplo de GitHub Actions
- name: Test
  run: flutter test

- name: Analyze
  run: flutter analyze lib

- name: Coverage
  run: flutter test --coverage
```
