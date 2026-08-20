<div align="center">

# Supertonic AudioBook

**Convierte archivos Markdown en audiolibros con voz sintética. 100 % local.**

[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-369%20passed-brightgreen)](#testing)
[![Docs](https://img.shields.io/badge/docs-ES%20%7C%20EN-blue)](#documentación)

Sin nube. Sin API. Sin GPU. Todo ocurre en tu dispositivo.

[Características](#características) · [Instalación](#instalación) · [Uso](#uso) · [Arquitectura](#arquitectura) · [Documentación](#documentación) · [Testing](#testing)

</div>

---

## Características

| | Función | Descripción |
|---|---------|-------------|
| 🎙️ | **Conversión MD → Audio** | Lee archivos `.md` (carpeta o sueltos), limpia Markdown, segmenta y sintetiza voz |
| 🎧 | **Gestión de audios pendientes** | Revisá, renombrá y guardá cada audio recién generado antes de publicarlo |
| 📚 | **Biblioteca** | Audios generados con play/pausa |
| 🏷️ | **Editor de metadatos** | Tags ID3 de MP3: título, artista, álbum, año, género, pista, carátula |
| ⚡ | **Benchmark del motor** | Mide chars/seg de tu dispositivo en 6 tamaños y estima tiempos de conversión |
| 🌍 | **31 idiomas + auto** | Voces sintéticas en español, inglés, francés, alemán, japonés y más |
| 📱 | **Responsive** | Móvil: acordeones apilados · Tablet (≥ 900 px): paneles lado a lado |
| 🔄 | **Descarga resumible** | Modelo Supertonic 3 (~400 MB) con verificación SHA-256 |

## Instalación

### Requisitos

- Flutter SDK `^3.5.0`
- Dart SDK `^3.12.2`
- Android SDK (API 21+)

### Pasos

```bash
git clone https://github.com/Rafael-VH/Supertonic-AudioBook-Flutter.git
cd Supertonic-AudioBook-Flutter

flutter pub get
flutter gen-l10n
flutter run
```

> **Nota:** La primera ejecución descarga el modelo de voz (~400 MB). Es una sola vez, resumible, y queda guardado en tu dispositivo.

## Uso

### Flujo principal

```
1ª ejecución                              Ejecuciones siguientes
    │                                          │
    ▼                                          ▼
 Splash ──→ Onboarding ──→ Dashboard      Splash ──→ Dashboard
                               │                          │
              ┌────────────────┼────────────────┐        │
              ▼                ▼                ▼        │
           Home           Biblioteca        Settings     │
              │                                │        │
    ┌─────────┴──────────┐          ┌─────────┤        │
    ▼                    ▼          ▼         ▼        │
 Convertir           Editor ID3  Audios   Configuración │
 (carpeta o           (tags      generados  (voz, tema, │
  archivos .md)        MP3)      (play/     idioma,      │
              │                   pausa)    benchmark)   │
              ▼                                     │
 AudioManager                                      │
 (renombrar,                                       │
  guardar,                                         │
  cancelar) ────────────────────────────────────────┘
```

**Dashboard** = `NavigationBar` con 3 pestañas: Home (hub), Biblioteca, Settings.

**Convertir**:
1. Tocá **Convertir archivos** en Home → elegí carpeta o archivos `.md`
2. Configurá voz, velocidad, pasos e idioma en **Opciones**
3. Tocá **Procesar** — los archivos se convierten secuencialmente con registro en vivo
4. Al terminar se abre **AudioManager**: renombrá, elegí carpeta y guardá (o cancelá para descartar WAVs temporales)

**Biblioteca**: lista los audios guardados en la carpeta de salida con play/pausa.

**Benchmark** (Settings → Benchmark): medí chars/seg en tu dispositivo (6 tamaños, 2500–15000 chars). Resultado usado para estimar tiempos de conversión.

## Arquitectura

Clean Architecture con módulos por feature y capa compartida:

```
lib/
├── core/                        # Utilidades de bajo nivel
│   ├── audio/wav_io.dart            # Escritura WAV PCM16
│   └── utils/natural_sort.dart      # Ordenamiento natural
│
├── shared/                      # Infraestructura compartida entre features
│   ├── data/
│   │   ├── config.dart              # Constantes técnicas del pipeline
│   │   └── repositories/            # Archivos, preferencias JSON, reproductor, logger
│   └── domain/
│       ├── constants/producto.dart  # Valores por defecto del producto
│       ├── contracts/               # Interfaces compartidas
│       └── entities/                # Archivo, VoiceConfig, AppPreferences
│
├── features/                    # Módulos por feature (cada uno autocontenido)
│   ├── audio_manager/           # Audios pendientes: guardar/cancelar/limpiar temps
│   ├── benchmark/               # Benchmark del motor + historial de conversiones
│   ├── biblioteca/              # Audios generados con play/pausa
│   ├── convert/                 # Conversión MD → Audio (core de la app)
│   ├── dashboard/               # Shell con NavigationBar (3 pestañas)
│   ├── editor_metadata/         # Edición de metadatos ID3
│   ├── home/                    # Hub de funciones (FunctionCards)
│   ├── modelo/                  # Descarga y verificación del modelo TTS
│   ├── onboarding/              # Guía de primera ejecución
│   ├── settings/                # Preferencias de la app
│   └── splash/                  # Pantalla de carga
│
├── presentation/                # Capa compartida de presentación
│   ├── controllers/providers.dart  # Contratos + DI (Riverpod)
│   ├── l10n/                        # Internacionalización (ES/EN)
│   ├── routing/app_router.dart      # Navegación centralizada (go_router)
│   └── theme/                       # Tema y paleta de colores
│
├── app.dart                     # Widget raíz (MaterialApp.router)
└── main.dart                    # Composition root
```

Cada feature sigue Clean Architecture internamente:

```
features/convert/
├── domain/
│   ├── contracts/               # Interfaces abstractas del feature
│   ├── entities/                # Modelos de dominio
│   └── use_cases/               # Casos de uso puros
├── data/
│   ├── helpers/                 # Helpers específicos del feature
│   └── repositories/            # Implementaciones concretas
└── presentation/
    ├── controllers/             # State management (Riverpod)
    ├── screens/                 # Pantallas (movil/ y tablet/)
    └── widgets/                 # Componentes UI del feature
```

### Regla de dependencia

```
features/X/presentation → features/X/domain ← features/X/data
       ↑                                        ↑
       └──── main.dart (providers.dart) ────────┘
```

- `domain/` **nunca** importa `data/` ni usa `dart:io`
- `presentation/` **nunca** importa `data/` directamente
- `shared/domain/` define contratos usados por múltiples features
- `shared/data/` provee implementaciones de contratos compartidos
- La inyección ocurre en `main.dart` con overrides de Riverpod en `providers.dart`

### Stack técnico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| State | flutter_riverpod | 3.4.2 |
| Routing | go_router | 17.5 |
| TTS | flutter_onnxruntime | 1.8.3 |
| Export | ffmpeg_kit_flutter_new | 4.6.2 |
| Playback | just_audio | 0.10.5 |
| Prefs | JSON local (`PreferenciasJsonLocal`) | — |
| Files | file_picker | 11.0.3 |
| ID3 tags | id3_codec | 1.0.3 |
| Download | dio + crypto (SHA-256) | 5.11 / 3.0 |

## Testing

```bash
flutter test              # Todos los tests
flutter analyze lib       # Análisis estático
flutter test --coverage   # Cobertura
```

Los tests espejan la estructura de `lib/`: `test/features/<feature>/...`, `test/presentation/...`, `test/core/`, `test/shared/`.

### Métricas

- **369 tests** en 45 archivos · algunos skips requieren FFmpeg nativo
- **0 análisis warnings** (`flutter analyze lib` limpio)

Ver [testing.md](docs/es/testing.md) para convenciones completas.

## Configuración técnica

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `silenceSamples` | 26,460 | Silencio entre fragmentos (0.6 s @ 44100 Hz) |
| `memoriaSafeMarginBytes` | 500 MB | Presupuesto de RAM desktop |
| `memoriaSafeMarginBytesMovil` | 64 MB | Presupuesto de RAM móvil (evita OOM) |
| `defaultTtsSteps` | 5 | Pasos de síntesis por defecto (rango 5–12) |
| `defaultSpeed` | 1.1 | Velocidad de voz por defecto (rango 0.7–2.0) |
| `defaultVoice` | `'M1'` | Voz por defecto (M1–M5, F1–F5) |

## Formatos de audio

| Formato | Método | Notas |
|---------|--------|-------|
| MP3 | WAV temporal → FFmpeg | **Formato por defecto** |
| WAV | `wav_io.dart` (Dart puro) | PCM16, sin dependencias |
| FLAC | WAV temporal → FFmpeg | Lossless |
| OGG | WAV temporal → FFmpeg | Vorbis |

La síntesis siempre produce un WAV temporal en `<carpeta_salida>/_temp/`; los formatos adicionales se convierten desde ese WAV.

## Contribuir

1. Fork el repositorio
2. Crear una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Hacer commit (`git commit -m 'feat: describir cambio'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abrir un Pull Request

### Convenciones

- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, etc.)
- **Tests**: Incluir tests para cada cambio de comportamiento
- **i18n**: Solo editar `app_es.arb` y `app_en.arb`, luego `flutter gen-l10n`
- **Arquitectura**: Respetar la regla de dependencia (domain no importa data)

## Documentación

Documentación completa del proyecto disponible en español e inglés.

| Tema | Español | English |
|------|---------|---------|
| Arquitectura | [architecture.md](docs/es/architecture.md) | [architecture.md](docs/en/architecture.md) |
| Pantallas | [screens.md](docs/es/screens.md) | [screens.md](docs/en/screens.md) |
| Navegación | [routing.md](docs/es/routing.md) | [routing.md](docs/en/routing.md) |
| Pipeline de Audio | [pipeline.md](docs/es/pipeline.md) | [pipeline.md](docs/en/pipeline.md) |
| Configuración | [configuration.md](docs/es/configuration.md) | [configuration.md](docs/en/configuration.md) |
| Testing | [testing.md](docs/es/testing.md) | [testing.md](docs/en/testing.md) |
| Internacionalización | [i18n.md](docs/es/i18n.md) | [i18n.md](docs/en/i18n.md) |
| ONNX Runtime | [onnx-runtime.md](docs/es/onnx-runtime.md) | [onnx-runtime.md](docs/en/onnx-runtime.md) |
| Modelo Supertonic 3 | [supertonic-3-model.md](docs/es/supertonic-3-model.md) | [supertonic-3-model.md](docs/en/supertonic-3-model.md) |

### Roadmap

Funcionalidades recomendadas y su estado: [funcionalidades-recomendadas.md](docs/funcionalidades-recomendadas.md).

Planes históricos de fases anteriores: [docs/plan/](docs/plan/) (referencia — las rutas de código que citan corresponden a la estructura previa a la refactorización).

## Licencia

[MIT](LICENSE)

---

<div align="center">

Hecho con ❤️ y Flutter

</div>
