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
| Tests totales | 228 |
| Pasaron | 228 |
| Omitidos | 4 (dependen de FFmpeg) |
| Cobertura (change activo) | ≥ 94% |
| Análisis | 0 warnings |

## Estructura de Tests

```
test/
├── core/
│   ├── audio/
│   │   └── wav_io_test.dart              # Escritura WAV PCM16
│   └── utils/
│       └── natural_sort_test.dart         # Ordenamiento natural
│
├── data/
│   ├── modelo/
│   │   └── modelo_manager_test.dart       # Descarga/verificación de modelo
│   └── repositories/
│       ├── exportador_audio_ffmpeg_test.dart  # Exportación FFmpeg
│       ├── repositorio_archivos_test.dart     # Operaciones de archivos
│       └── repositorio_preferencias_test.dart # Preferencias
│
├── domain/
│   └── use_cases/
│       ├── procesar_archivo_test.dart         # Procesar archivo (unitario)
│       ├── procesar_archivo_integration_test.dart  # Procesar archivo (integración)
│       ├── limpiar_markdown_test.dart         # Limpieza de Markdown
│       ├── segmentar_texto_test.dart          # Segmentación de texto
│       ├── sintetizar_muestra_test.dart       # Vista previa de voz
│       ├── listar_audios_generados_test.dart  # Listado de audios
│       └── formato_test.dart                  # Validación de formatos
│
├── features/
│   └── editor_metadata/
│       ├── data/repositories/
│       │   └── editor_metadata_id3_codec_test.dart  # Codec ID3
│       ├── domain/
│       │   ├── contracts/
│       │   │   └── editor_metadata_test.dart         # Contrato EditorMetadata
│       │   ├── entities/
│       │   │   └── metadatos_mp3_test.dart           # Entidad MetadatosMp3
│       │   └── use_cases/
│       │       └── editar_metadata_mp3_test.dart     # Editar metadatos
│       └── presentation/
│           ├── controllers/
│           │   └── metadata_editor_controller_test.dart  # Controller
│           └── screens/
│               └── metadata_editor_screen_test.dart      # UI
│
└── presentation/
    ├── controllers/
    │   ├── home_controller_test.dart       # Estado de Home
    │   ├── biblioteca_controller_test.dart # Estado de Biblioteca
    │   ├── modelo_controller_test.dart     # Estado de pantalla Modelo
    │   └── providers_test.dart             # Overrides de providers
    │
    ├── routing/
    │   └── app_router_test.dart            # Navegación/redirects
    │
    ├── screens/
    │   ├── convert_screen_test.dart        # UI de Convert
    │   ├── home_movil_diag_test.dart       # Layout móvil de Convert
    │   ├── settings_screen_test.dart       # UI de Settings
    │   ├── dashboard_screen_test.dart      # UI de Dashboard
    │   ├── modelo_screen_test.dart         # UI de pantalla Modelo
    │   └── biblioteca/
    │       └── biblioteca_screen_test.dart # UI de Biblioteca
    │
    └── theme/
        └── paleta_test.dart                # Paleta de colores
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

El test de integración de `ProcesarArchivo` verifica el pipeline completo:

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
  // Verificar que no hay imports de data/ en archivos de domain/
  // dentro de cada feature (features/X/domain/ no importa features/X/data/)
  // ni shared/domain/ no importa shared/data/
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

### Objetivos de Cobertura

| Capa | Objetivo |
|------|----------|
| Casos de uso de dominio | ≥ 95% |
| Controllers | ≥ 90% |
| Pantallas | ≥ 85% |
| General | ≥ 90% |

## Tests Omitidos

4 tests omitidos por dependencia de FFmpeg:

```dart
// Estos tests requieren el binario nativo de ffmpeg_kit
skip: 'Requiere binario nativo de FFmpeg',
```

Son tests de nivel de integración que solo pueden ejecutarse en dispositivos reales con FFmpeg instalado.

## Ejecutar Tests Específicos

```bash
# Ejecutar un solo archivo de test
flutter test test/domain/use_cases/limpiar_markdown_test.dart

# Ejecutar un test específico
flutter test --name "limpiarMarkdown elimina encabezados"

# Ejecutar con cobertura para archivos específicos
flutter test --coverage test/domain/
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
