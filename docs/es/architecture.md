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
│  │  domain/contracts/  entities  use_cases  constants            │   │
│  │  data/config.dart   repositories (archivos, prefs, player)   │   │
│  │  ⚠ NO dart:io en domain/                                     │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ injected in
                                     ▼
                          lib/main.dart + providers.dart
                        (composition root + DI)
```

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
- Cada feature es autocontenida: puede modificarce sin afectar otras features

## Composition Root (`lib/main.dart` + `providers.dart`)

`main.dart` es el único archivo que importa implementaciones concretas de `data/`. Hace:

1. Inicializar bindings (WidgetsFlutterBinding / FdbBinding)
2. Resolver rutas de plataforma (documents, support, modelo)
3. Crear implementaciones concretas
4. Inyectar todo en overrides de `ProviderScope` via `providers.dart`

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

`providers.dart` define los contratos de `domain/` como providers de Riverpod. Es el punto de entrada único a las implementaciones concretas.

### Mapa de Inyección de Providers

| Provider | Implementación | Ubicación |
|----------|---------------|-----------|
| `repositorioArchivosProvider` | `RepositorioArchivosLocal` | `shared/data/repositories/` |
| `repositorioPreferenciasProvider` | `PreferenciasJsonLocal` | `shared/data/repositories/` |
| `exportadorAudioProvider` | `ExportadorAudioFfmpeg` | `features/convert/data/repositories/` |
| `reproductorAudioProvider` | `ReproductorJustAudio` | `shared/data/repositories/` |
| `motorTtsProvider` | `MotorTtsSupertonic` | `features/convert/data/repositories/` |
| `modeloManagerProvider` | `ModeloManager` | `features/modelo/data/repositories/` |
| `editorMetadataProvider` | `EditorMetadataId3Codec` | `features/editor_metadata/data/repositories/` |
| `configTtsProvider` | Record inline | `providers.dart` |
| `carpetaBaseProvider` | Ruta de plataforma | `main.dart` |

## Capa de Dominio

### Contratos Compartidos (`shared/domain/contracts/`)

Interfaces abstractas usadas por múltiples features.

| Contrato | Responsabilidad |
|----------|----------------|
| `RepositorioArchivos` | Listar/leer archivos, crear directorios |
| `RepositorioPreferencias` | Cargar/guardar preferencias clave-valor |
| `ReproductorAudio` | Reproducir/pausar/detener audio local |

### Contratos por Feature (`features/X/domain/contracts/`)

Interfaces específicas de cada feature.

| Contrato | Feature | Responsabilidad |
|----------|---------|----------------|
| `MotorTts` | convert | Sintetizar texto → muestras de audio Float32 |
| `ExportadorAudio` | convert | Escribir archivos de audio (WAV/MP3/FLAC/OGG) |
| `ModeloGestor` | modelo | Descargar, verificar y gestionar el modelo TTS |
| `EditorMetadata` | editor_metadata | Editar metadatos ID3 de archivos MP3 |

### Entidades

| Entidad | Feature | Descripción |
|---------|---------|-------------|
| `Archivo` | convert | Un archivo Markdown a convertir (extiende `Equatable`) |
| `LibroGenerado` | biblioteca | Un audiolibro agrupado con prioridad de formato |
| `MetadatosMp3` | editor_metadata | Metadatos ID3 de un archivo MP3 |

### Casos de Uso

| Caso de Uso | Feature | Propósito |
|-------------|---------|-----------|
| `ProcesarArchivo` | convert | Convertir MD → audio (pipeline completo) |
| `LimpiarMarkdown` | convert | Eliminar sintaxis Markdown → texto plano |
| `SegmentarTexto` | convert | Dividir texto en chunks listos para TTS |
| `SintetizarMuestra` | convert | Generar vista previa de voz |
| `Formato` | convert | Validar y normalizar formatos de salida |
| `ListarAudiosGenerados` | biblioteca | Agrupar audios generados por libro |
| `EditarMetadataMp3` | editor_metadata | Editar metadatos ID3 en archivos MP3 |

## Capa de Datos

### Repositorios Compartidos (`shared/data/repositories/`)

Implementaciones concretas de contratos compartidos.

| Repositorio | Implementa | Tecnología |
|------------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | `shared_preferences` |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |

### Repositorios por Feature

| Repositorio | Feature | Implementa | Tecnología |
|------------|---------|-----------|------------|
| `ExportadorAudioFfmpeg` | convert | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `MotorTtsSupertonic` | convert | `MotorTts` | `flutter_onnxruntime` |
| `ModeloManager` | modelo | `ModeloGestor` | `Dio` |
| `EditorMetadataId3Codec` | editor_metadata | `EditorMetadata` | ID3 codec |

### Gestor de Modelo (`features/modelo/data/repositories/modelo_manager.dart`)

`ModeloManager` maneja la descarga y verificación del modelo Supertonic 3 (~400 MB):

- Descargas resumibles con `Dio`
- Verificación de integridad SHA-256 en Isolate
- Soporte de cancelación/timeout
- Almacena el modelo en `<app_support>/modelo/onnx/` y `voice_styles/`

### Configuración (`shared/data/config.dart`)

Constantes técnicas del pipeline TTS:

```dart
const double silenceDurationSecs = 0.6;    // silencio entre fragmentos
const int silenceSamples = 26460;           // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB móvil
```

## Capa de Presentación

### Pantallas por Feature (`features/X/presentation/screens/`)

Cada feature tiene sus propias pantallas. La pantalla principal de conversión es `ConvertScreen` (antes `HomeScreen`):

| Pantalla | Feature | Archivo |
|----------|---------|---------|
| SplashScreen | splash | `features/splash/presentation/screens/splash_screen.dart` |
| OnboardingScreen | onboarding | `features/onboarding/presentation/screens/onboarding_screen.dart` |
| DashboardScreen | dashboard | `features/dashboard/presentation/screens/dashboard_screen.dart` |
| ConvertScreen | convert | `features/convert/presentation/screens/convert_screen.dart` |
| ModeloScreen | modelo | `features/modelo/presentation/screens/modelo_screen.dart` |
| BibliotecaScreen | biblioteca | `features/biblioteca/presentation/screens/biblioteca_screen.dart` |
| SettingsScreen | settings | `features/settings/presentation/screens/settings_screen.dart` |
| MetadataEditorScreen | editor_metadata | `features/editor_metadata/presentation/screens/metadata_editor_screen.dart` |

### Controllers por Feature (`features/X/presentation/controllers/`)

| Controller | Feature | Responsabilidad |
|-----------|---------|----------------|
| `HomeController` | convert | Estado de conversión (HomeEstado) |
| `SettingsController` | settings | Preferencias de la app |
| `BibliotecaController` | biblioteca | Estado de la biblioteca |
| `ModeloController` | modelo | Estado de descarga del modelo |
| `MetadataEditorController` | editor_metadata | Estado del editor de metadatos |

### Gestión de Estado (Riverpod)

- **Notifiers** para estado complejo: `HomeController`, `SettingsController`
- **Providers** para contratos y casos de uso (definidos en `providers.dart`)
- **Clases de estado**: `HomeEstado`, `SettingsEstado` (inmutables con `copyWith`)

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
}
```

Ver [routing.md](routing.md) para detalles del flujo de navegación.

### Tema (`presentation/theme/`)

- `AppTheme` con `ThemeMode` (oscuro/claro) y variantes `AppEstilo`
- Sistema de paleta (`Paleta`) para colores consistentes
- Se aplica con `construirTema()` en `app.dart`

### Internacionalización (`presentation/l10n/`)

- Archivos ARB: `app_es.arb`, `app_en.arb`
- Generados con `flutter gen-l10n`
- Nunca editar archivos `.dart` generados directamente

## Estrategia de Testing

### Tests de Arquitectura

Verifican la regla de dependencia: `domain/` nunca importa `data/` ni `dart:io`.

### Tests Unitarios

- **Casos de uso de dominio**: Lógica pura, sin mocks
- **Controllers**: Contratos mockeados con `mocktail`

### Tests de Widget

- **Pantallas**: Árboles completos de widgets con providers mockeados
- **Routing**: Navegación y lógica de redirects

### Puntos de Integración

- `ProcesarArchivo` tiene tests de integración con el pipeline real
- Patrón `ExportadorSelectivo` para testear exportación de formatos independientemente

### Estructura de Tests

```
test/
├── core/                          # WAV I/O, natural sort
├── data/                          # Repositorios compartidos
├── domain/                        # Casos de uso compartidos
├── features/editor_metadata/      # Tests del feature editor_metadata
│   ├── data/repositories/
│   ├── domain/{contracts,entities,use_cases}/
│   └── presentation/{controllers,screens}/
├── presentation/
│   ├── controllers/               # Controllers (home, biblioteca, modelo, providers)
│   ├── screens/                   # Widgets de pantalla
│   ├── routing/                   # Navegación y redirects
│   └── theme/                     # Paleta y estilos visuales
└── support/                       # Helpers de test
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

### 4. Publicación Atómica

Los archivos de audio se publican mediante rename (atómico en la mayoría de sistemas de archivos). Al cancelar, se preservan los archivos existentes — nunca se reemplazan con output truncado.
