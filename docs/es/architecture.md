# Arquitectura

Clean Architecture con reglas de dependencia estrictas en tres capas.

## Resumen

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
│  ⚠ implementaciones concretas de contratos domain   │
└─────────────────────────────────────────────────────┘
                           │
                           │ injected in
                           ▼
                   lib/main.dart
              (composition root)
```

## Regla de Dependencia

**`domain/` nunca importa `data/` ni usa `dart:io`.**

Este es el invariante central. Las violaciones se detectan con `flutter analyze` y tests de arquitectura.

- `domain/contracts/` define interfaces abstractas (ej. `MotorTts`, `ExportadorAudio`)
- `data/` provee implementaciones concretas (ej. `MotorTtsSupertonic`, `ExportadorAudioFfmpeg`)
- `main.dart` los conecta mediante overrides de Riverpod

### Por qué importa

- Los use cases de dominio son testeables sin dependencias de plataforma
- Cambiar implementaciones (ej. ffmpeg → encoder nativo) requiere cero cambios en dominio
- `dart:io` (sistema de archivos, detección de plataforma) vive en `data/` y `presentation/`

## Composition Root (`lib/main.dart`)

El único archivo que importa `data/` y `presentation/`. Hace:

1. Inicializar bindings (WidgetsFlutterBinding / FdbBinding)
2. Resolver rutas de plataforma (documents, support, modelo)
3. Crear implementaciones concretas
4. Inyectar todo en overrides de `ProviderScope`

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

### Mapa de Inyección de Providers

| Provider | Implementación | Ubicación |
|----------|---------------|-----------|
| `repositorioArchivosProvider` | `RepositorioArchivosLocal` | `data/repositories/` |
| `repositorioPreferenciasProvider` | `PreferenciasJsonLocal` | `data/repositories/` |
| `exportadorAudioProvider` | `ExportadorAudioFfmpeg` | `data/repositories/` |
| `reproductorAudioProvider` | `ReproductorJustAudio` | `data/repositories/` |
| `motorTtsProvider` | `MotorTtsSupertonic` | `data/repositories/` |
| `modeloManagerProvider` | `ModeloManager` | `data/modelo/` |
| `configTtsProvider` | Record inline | `main.dart` |
| `carpetaBaseProvider` | Ruta de plataforma | `main.dart` |

## Capa de Dominio

### Contratos (`domain/contracts/`)

Interfaces abstractas que definen qué necesita el dominio, no cómo se implementa.

| Contrato | Responsabilidad |
|----------|----------------|
| `MotorTts` | Sintetizar texto → muestras de audio Float32 |
| `ExportadorAudio` | Escribir archivos de audio (WAV/MP3/FLAC/OGG) |
| `RepositorioArchivos` | Listar/leer archivos, crear directorios |
| `RepositorioPreferencias` | Cargar/guardar preferencias clave-valor |
| `ReproductorAudio` | Reproducir/pausar/detener audio local |
| `ModeloGestor` | Descargar, verificar y gestionar el modelo TTS |

### Entidades (`domain/entities/`)

Modelos de datos puros sin dependencias externas.

| Entidad | Descripción |
|---------|-------------|
| `Archivo` | Un archivo Markdown a convertir (extiende `Equatable`) |
| `LibroGenerado` | Un audiolibro agrupado con prioridad de formato |

### Casos de Uso (`domain/use_cases/`)

Lógica de orquestación que depende solo de contratos y entidades.

| Caso de Uso | Propósito |
|-------------|-----------|
| `ProcesarArchivo` | Convertir MD → audio (pipeline completo) |
| `LimpiarMarkdown` | Eliminar sintaxis Markdown → texto plano |
| `SegmentarTexto` | Dividir texto en chunks listos para TTS |
| `SintetizarMuestra` | Generar vista previa de voz |
| `ListarAudiosGenerados` | Agrupar audios generados por libro |
| `Formato` | Validar y normalizar formatos de salida |

## Capa de Datos

### Repositorios (`data/repositories/`)

Implementaciones concretas de contratos de dominio.

| Repositorio | Implementa | Tecnología |
|------------|-----------|------------|
| `RepositorioArchivosLocal` | `RepositorioArchivos` | `dart:io` |
| `PreferenciasJsonLocal` | `RepositorioPreferencias` | `shared_preferences` |
| `ExportadorAudioFfmpeg` | `ExportadorAudio` | `ffmpeg_kit` + `wav_io.dart` |
| `ReproductorJustAudio` | `ReproductorAudio` | `just_audio` |
| `MotorTtsSupertonic` | `MotorTts` | `flutter_onnxruntime` |

### Gestor de Modelo (`data/modelo/`)

`ModeloManager` maneja la descarga y verificación del modelo Supertonic 3 (~400 MB):

- Descargas resumibles con `Dio`
- Verificación de integridad SHA-256 en Isolate
- Soporte de cancelación/timeout
- Almacena el modelo en `<app_support>/modelo/onnx/` y `voice_styles/`

### Configuración (`data/config.dart`)

Constantes técnicas del pipeline TTS:

```dart
const double silenceDurationSecs = 0.6;    // silencio entre fragmentos
const int silenceSamples = 26460;           // 44100 Hz × 0.6 s
const int memoriaSafeMarginBytes = 524288000;      // 500 MB desktop
const int memoriaSafeMarginBytesMovil = 67108864;  // 64 MB móvil
```

## Capa de Presentación

### Gestión de Estado (Riverpod)

- **Notifiers** para estado complejo: `HomeController`, `SettingsController`
- **Providers** para contratos y casos de uso
- **Clases de estado**: `HomeEstado`, `SettingsEstado` (inmutables con `copyWith`)

### Routing (go_router)

Centralizado en `lib/presentation/routing/app_router.dart`:

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
