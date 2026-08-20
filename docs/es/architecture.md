# Arquitectura

Clean Architecture con módulos por feature y capa compartida (`shared/`).

## Resumen

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
│  │  ⚠ NO dart:io en domain/                                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ injected in
                                     ▼
                          lib/main.dart + providers.dart
                        (composition root + DI)
```

**Features**: `audio_manager`, `benchmark`, `biblioteca`, `convert`, `dashboard`, `editor_metadata`, `home`, `modelo`, `onboarding`, `settings`, `splash`.

## Regla de Dependencia

**`domain/` nunca importa `data/` ni usa `dart:io`.**

Este es el invariante central. Las violaciones se detectan con `flutter analyze` y tests de arquitectura.

- Cada feature tiene sus propios contratos en `features/X/domain/contracts/` (ej. `MotorTts`, `ExportadorAudio`)
- `shared/domain/contracts/` define contratos usados por múltiples features (ej. `RepositorioArchivos`, `RepositorioPreferencias`)
- `features/X/data/` provee implementaciones concretas del feature
- `shared/data/` provee implementaciones de contratos compartidos
- `main.dart` los conecta mediante overrides de Riverpod en `providers.dart`

### Por qué importa

- Los use cases de dominio son testeables sin dependencias de plataforma
- Cambiar implementaciones (ej. ffmpeg → encoder nativo) requiere cero cambios en dominio
- `dart:io` (sistema de archivos, detección de plataforma) vive en `data/` y `presentation/`
- Cada feature es autocontenida: puede modificarse sin afectar otras features

## Composition Root (`lib/main.dart` + `providers.dart`)

`main.dart` es el único archivo que importa implementaciones concretas de `data/`. Hace:

1. Inicializar bindings (WidgetsFlutterBinding / FdbBinding según modo release)
2. Limpiar WAVs huérfanos de ejecuciones anteriores (`LimpiarTemporales`, > 24 h)
3. Resolver rutas de plataforma (documents, support, modelo)
4. Crear implementaciones concretas
5. Inyectar todo en overrides de `ProviderScope` via `providers.dart`

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

`providers.dart` define los contratos de `domain/` como providers de Riverpod que **fallan rápido si se usan sin inyección**. Es el punto de entrada único a las implementaciones concretas.

### Mapa de Inyección de Providers

| Provider | Implementación | Ubicación |
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
| `configTtsProvider` | Record `TtsConfig` | `providers.dart` |
| `carpetaBaseProvider` | Ruta de plataforma | `main.dart` |

Los tres repositorios JSON (`preferencias`, `benchmark`, `historial_conversiones`) son instancias separadas de la misma clase `PreferenciasJsonLocal`.

## Capa de Dominio

### Contratos Compartidos (`shared/domain/contracts/`)

Interfaces abstractas usadas por múltiples features.

| Contrato | Responsabilidad |
|----------|----------------|
| `RepositorioArchivos` | Listar/leer/mover/eliminar archivos, crear directorios |
| `RepositorioPreferencias` | Cargar/guardar preferencias clave-valor (JSON) |
| `ReproductorAudio` | Reproducir/pausar/reanudar/detener audio local |
| `DomainLogger` | Logging abstracto (implementado por `PrintLogger`) |

### Contratos por Feature (`features/X/domain/contracts/`)

| Contrato | Feature | Responsabilidad |
|----------|---------|----------------|
| `MotorTts` | convert | Sintetizar texto → muestras de audio Float32 |
| `ExportadorAudio` | convert | Escribir/convertir archivos de audio (WAV/MP3/FLAC/OGG) |
| `FileSystemContract` | convert | Operaciones de rutas (parentOf, fileName, separator) |
| `ModeloGestor` | modelo | Descargar, verificar y gestionar el modelo TTS |
| `EditorMetadata` | editor_metadata | Leer/escribir metadatos ID3 de archivos MP3 |

### Entidades

| Entidad | Feature | Descripción |
|---------|---------|-------------|
| `Archivo` | shared | Un archivo Markdown a convertir (extiende `Equatable`) |
| `VoiceConfig` | shared | Voz + steps + speed + idioma de síntesis |
| `AppPreferences` | shared | Preferencias tipadas de la app |
| `LibroGenerado` | biblioteca | Un audiolibro agrupado con prioridad de formato |
| `MetadatosMp3` | editor_metadata | Metadatos ID3 de un archivo MP3 |
| `AudioPendiente` | audio_manager | WAV temporal esperando guardar/cancelar |
| `BenchmarkResult` | benchmark | Resultados del benchmark por tamaño |
| `ConversionEntry` | benchmark | Métricas de una conversión (chars, segmentos, duración) |

### Casos de Uso

| Caso de Uso | Feature | Propósito |
|-------------|---------|-----------|
| `ProcesarArchivo` | convert | Convertir MD → WAV temporal en `_temp/` |
| `LimpiarMarkdown` | convert | Eliminar sintaxis Markdown → texto plano |
| `SegmentarTexto` | convert | Dividir texto en chunks listos para TTS |
| `SintetizarMuestra` | convert | Generar vista previa de voz |
| `Formato` | convert | Validar y normalizar formatos de salida |
| `ListarAudiosGenerados` | biblioteca | Agrupar audios generados por libro |
| `EditarMetadataMp3` | editor_metadata | Editar metadatos ID3 en archivos MP3 |
| `GuardarAudio` | audio_manager | Mover WAV temporal → destino final (con sufijo `(N)` en conflicto) |
| `LimpiarTemporales` | audio_manager | Eliminar WAVs temporales con más de 24 h |
| `EstimarMemoria` | audio_manager | Presupuesto de memoria del lote antes de procesar |
| `RunBenchmark` | benchmark | Ejecutar benchmark en un tamaño de texto |
| `EstimarTiempo` | benchmark | Estimar duración de conversión desde el benchmark |

## Capa de Datos

### Repositorios Compartidos (`shared/data/repositories/`)

| Repositorio | Implementa | Tecnología |
|------------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | Archivo JSON local |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |
| `PrintLogger` | `DomainLogger` | Consola |

### Repositorios por Feature

| Repositorio | Feature | Implementa | Tecnología |
|------------|---------|-----------|------------|
| `ExportadorAudioFfmpeg` | convert | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `MotorTtsSupertonic` | convert | `MotorTts` | `flutter_onnxruntime` |
| `FileSystemLocal` | convert | `FileSystemContract` | `dart:io` |
| `ModeloManager` | modelo | `ModeloGestor` | `Dio` + `crypto` |
| `EditorMetadataId3Codec` | editor_metadata | `EditorMetadata` | `id3_codec` |

### Gestor de Modelo (`features/modelo/data/repositories/modelo_manager.dart`)

`ModeloManager` maneja la descarga y verificación del modelo Supertonic 3 (~400 MB, 15 archivos):

- Descargas resumibles con `Dio` (header `Range`, append sobre `.part`)
- Verificación SHA-256 para los ONNX (en Isolate); tamaño exacto + parseo JSON para configs y estilos de voz
- Soporte de cancelación/timeout
- Almacena el modelo en `<app_support>/modelo/onnx/` y `voice_styles/`

### Configuración (`shared/data/config.dart`)

Constantes técnicas del pipeline TTS:

```dart
const double silenceDurationSecs = 0.6;            // silencio entre fragmentos
const int silenceSamples = 26460;                  // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB móvil
```

## Capa de Presentación

### Pantallas por Feature (`features/X/presentation/screens/`)

| Pantalla | Feature | Ruta |
|----------|---------|------|
| SplashScreen | splash | `/splash` |
| OnboardingScreen | onboarding | `/onboarding` |
| DashboardScreen | dashboard | `/dashboard` (shell NavigationBar) |
| HomeScreen (hub) | home | tab 0 del dashboard |
| ConvertScreen | convert | `/home` |
| ModeloScreen | modelo | `/modelo` |
| BibliotecaScreen | biblioteca | `/biblioteca` (tab 1 embebida) |
| SettingsScreen | settings | `/settings` (tab 2 embebida) |
| MetadataEditorScreen | editor_metadata | `/editor-metadata` |
| BenchmarkScreen | benchmark | `/benchmark` |
| AudioManagerScreen | audio_manager | `/audio-manager` |

Ver [screens.md](screens.md) para el detalle de cada pantalla.

### Controllers por Feature (`features/X/presentation/controllers/`)

| Controller | Feature | Responsabilidad |
|-----------|---------|----------------|
| `HomeController` | convert | Estado de conversión (`HomeEstado`), orquesta el lote |
| `SettingsController` | settings | Preferencias de la app |
| `BibliotecaController` | biblioteca | Estado de la biblioteca y reproducción |
| `ModeloController` | modelo | Estado de descarga del modelo |
| `MetadataEditorController` | editor_metadata | Estado del editor de metadatos |
| `BenchmarkController` | benchmark | Filas del benchmark e historial |
| `AudioManagerController` | audio_manager | Audios pendientes (guardar/cancelar) |

### Gestión de Estado (Riverpod)

- **Notifiers** para estado complejo: `HomeController`, `BibliotecaController`, etc.
- **Providers** para contratos y casos de uso (definidos en `providers.dart`)
- **Clases de estado**: `HomeEstado`, `BibliotecaEstado`, etc. (inmutables con `copyWith`)

### Routing (go_router)

Centralizado en `lib/presentation/routing/app_router.dart`:

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

Gates activos: splash decide onboarding vs dashboard; `/home` sin modelo redirige a `/modelo`. Ver [routing.md](routing.md).

### Tema (`presentation/theme/`)

- `AppTheme` con `ThemeMode` (oscuro/claro) y variantes `AppEstilo` (material/neumorfismo/skeuomorfismo)
- Sistema de paleta (`Paleta`) para colores consistentes
- Se aplica con `construirTema()` en `app.dart`

### Internacionalización (`presentation/l10n/`)

- Archivos ARB: `app_es.arb`, `app_en.arb` (template: `app_en.arb`)
- Generados con `flutter gen-l10n` (config en `l10n.yaml`)
- Nunca editar los `.dart` generados directamente

## Estrategia de Testing

### Tests de Arquitectura

Verifican la regla de dependencia: `domain/` nunca importa `data/` ni `dart:io`.

### Tests Unitarios

- **Casos de uso de dominio**: Lógica pura, sin mocks
- **Controllers**: Contratos mockeados con `mocktail`

### Tests de Widget

- **Pantallas**: Árboles completos de widgets con providers mockeados
- **Routing**: Navegación y lógica de redirects

### Estructura de Tests

Espeja `lib/` feature por feature:

```
test/
├── core/                        # WAV I/O, natural sort
├── shared/                      # Repositorios y entidades compartidas
├── features/                    # Un directorio por feature
│   ├── audio_manager/           # Entidades y use cases (guardar, limpiar)
│   ├── benchmark/               # Entidades, use cases, controller
│   ├── biblioteca/              # Use case listar audios
│   ├── convert/                 # Data, use cases, widgets
│   ├── editor_metadata/         # Codec ID3, entidad, controller, pantalla
│   └── modelo/                  # ModeloManager
├── presentation/                # Controllers compartidos, routing, screens, theme
└── support/                     # Helpers de test
```

Ver [testing.md](testing.md) para métricas y convenciones completas.

## Decisiones de Diseño Clave

### 1. Patrón Composition Root

Toda la inyección de dependencias ocurre en `main.dart`. Sin service locator, sin abstract factories — solo overrides de Riverpod.

**Tradeoff**: Más boilerplate en `main.dart`, pero explícito y testeable.

### 2. Nomenclatura Guiada por Dominio

Entidades y casos de uso usan nombres en español que coinciden con la implementación Python original:
- `Archivo` (no `MarkdownFile`)
- `ProcesarArchivo` (no `ProcessFile`)
- `HomeEstado` (no `HomeState`)

**Razón**: Consistencia con el codebase Python que precedió este rewrite en Flutter.

### 3. Presupuesto de Memoria para Móvil

Los dispositivos móviles tienen un umbral de memoria más bajo (64 MB vs 500 MB desktop) para prevenir OOM:

```dart
if (memoriaAcumulada > presupuesto) {
  await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
  fragmentos.clear();
}
```

Además, antes de iniciar un lote se estima la memoria requerida: si supera el 70 % de la disponible, se muestra un diálogo de advertencia.

### 4. Publicación Diferida (audio-manager)

La síntesis **nunca escribe en la ruta final**: produce WAVs temporales en `<salida>/_temp/` y los publica el usuario desde la pantalla de audios pendientes (rename atómico). Al cancelar, los temps se eliminan y los archivos existentes quedan intactos.
