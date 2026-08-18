<div align="center">

# Supertonic AudioBook

**Convierte archivos Markdown en audiolibros con voz sintética. 100 % local.**

[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-228%20passed-brightgreen)](#testing)
[![Docs](https://img.shields.io/badge/docs-ES%20%7C%20EN-blue)](#documentación)

Sin nube. Sin API. Sin GPU. Todo ocurre en tu dispositivo.

[Características](#características) · [Instalación](#instalación) · [Uso](#uso) · [Arquitectura](#arquitectura) · [Documentación](#documentación) · [Testing](#testing)

</div>

---

## Características

| | Función | Descripción |
|---|---------|-------------|
| 🎙️ | **Conversión MD → Audio** | Lee archivos `.md`, limpia Markdown, segmenta texto y sintetiza voz |
| 🎵 | **Multi-formato** | Exporta a WAV, MP3, FLAC y OGG (vía FFmpeg) |
| 🌍 | **31 idiomas** | Voces sintéticas en español, inglés, francés, alemán, japonés y más |
| 📱 | **Responsive** | Layout adaptado para móvil (acordeones) y tablet (cards) |
| 📚 | **Biblioteca** | Reproduce los audiolibros generados con play/pause |
| ⚡ | **On-device** | Motor Supertonic 3 vía ONNX Runtime — nada sale de tu dispositivo |
| 🔄 | **Descarga resumible** | Modelo de voz (~400 MB) con verificación de integridad |

## Instalación

### Requisitos

- Flutter SDK `^3.5.0`
- Dart SDK `^3.12.2`
- Android SDK (API 21+)

### Pasos

```bash
# Clonar el repositorio
git clone https://github.com/Rafael-VH/Supertonic-AudioBook-Flutter.git
cd Supertonic-AudioBook-Flutter

# Instalar dependencias
flutter pub get

# Generar localizaciones
flutter gen-l10n

# Ejecutar
flutter run
```

> **Nota:** La primera ejecución descarga el modelo de voz (~400 MB). Es una sola vez, resumible, y queda guardado en tu dispositivo.

## Uso

### Flujo principal

```
Dashboard
  ├─ "Convertir archivos a audio" → Home (seleccionar carpeta .md)
  ├─ "Procesar archivos sueltos"  → Selección (elegir archivos individuales)
  ├─ "Biblioteca"                 → Escuchar audiolibros generados
  └─ "Modelos"                    → Descargar / verificar modelo de voz
```

### Home — Procesamiento por lotes

1. Selecciona la carpeta con tus archivos `.md`
2. Configura voz, velocidad, pasos y formatos de salida
3. Toca **Procesar** — cada archivo se convierte secuencialmente
4. El registro muestra progreso detallado en tiempo real

### Selección — Archivos sueltos

1. Toca **Elegir archivos** para abrir el buscador del sistema
2. Selecciona uno o más archivos `.md` de cualquier ubicación
3. Procesa con las mismas opciones de síntesis

### Onboarding

Guía interactiva de 5 pasos al iniciar la app por primera vez:

1. Descargar el modelo de voz
2. Seleccionar archivos
3. Elegir voz
4. Procesar audio
5. **Seleccionar carpeta de salida** (nuevo)

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
│   │   └── repositories/            # Archivos, preferencias, reproductor
│   └── domain/
│       ├── constants/producto.dart  # Valores por defecto del producto
│       └── contracts/               # Interfaces compartidas
│
├── features/                    # Módulos por feature (cada uno autocontenido)
│   ├── biblioteca/             # Escuchar audiolibros generados
│   ├── convert/                # Conversión MD → Audio (core de la app)
│   ├── dashboard/              # Centro principal
│   ├── editor_metadata/        # Edición de metadatos ID3
│   ├── home/                   # Pantalla de inicio
│   ├── modelo/                 # Descarga del modelo TTS
│   ├── onboarding/             # Guía de primera ejecución
│   ├── settings/               # Preferencias de la app
│   └── splash/                 # Pantalla de carga
│
├── presentation/                # Capa compartida de presentación
│   ├── controllers/providers.dart  # Inyección de dependencias (Riverpod)
│   ├── l10n/                        # Internacionalización (ES/EN)
│   ├── routing/app_router.dart      # Navegación centralizada (go_router)
│   └── theme/                       # Tema y paleta de colores
│
├── app.dart                     # Widget raíz
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
| State | Riverpod | 3.4.2 |
| Routing | go_router | 17.5 |
| TTS | flutter_onnxruntime | 1.8.3 |
| Export | ffmpeg_kit_flutter_new | 4.6.2 |
| Playback | just_audio | 0.10.5 |
| Prefs | shared_preferences | 2.5.5 |
| Files | file_picker | 11.0.3 |
| Permissions | permission_handler | 13.0.1 |

## Testing

```bash
# Ejecutar todos los tests
flutter test

# Análisis estático
flutter analyze lib

# Coverage (requiere tool adicional)
flutter test --coverage
```

### Estructura de tests

| Directorio | Cubre |
|------------|-------|
| `test/core/` | WAV I/O, natural sort |
| `test/data/` | Repositorios compartidos |
| `test/domain/` | Casos de uso compartidos (procesar, segmentar, listar) |
| `test/features/editor_metadata/` | Editor de metadatos (domain, data, presentation) |
| `test/presentation/controllers/` | Controllers (home, biblioteca, modelo, providers) |
| `test/presentation/screens/` | Widgets de pantalla (convert, settings, dashboard, etc.) |
| `test/presentation/routing/` | Navegación y redirects |
| `test/presentation/theme/` | Paleta y estilos visuales |

### Métricas

- **228 tests** · 4 skips (requieren FFmpeg real)
- **Cobertura ≥94%** en archivos del change activo
- **0 análisis warnings** (`flutter analyze lib` limpio)

## Configuración técnica

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `silenceSamples` | 26,460 | Muestras de silencio entre fragmentos (0.6s @ 44100 Hz) |
| `memoriaSafeMarginBytes` | 500 MB | Umbral de RAM para desktop |
| `memoriaSafeMarginBytesMovil` | 64 MB | Umbral de RAM para móvil (evita OOM) |
| `defaultTtsSteps` | 8 | Pasos de síntesis por defecto |
| `defaultSpeed` | 1.0 | Velocidad de voz por defecto |

## Formatos de audio

| Formato | Método | Notas |
|---------|--------|-------|
| WAV | `escribirWav()` (Dart puro) | PCM16, sin dependencias |
| MP3 | WAV temporal → FFmpeg | Requiere ffmpeg_kit |
| FLAC | WAV temporal → FFmpeg | Lossless |
| OGG | WAV temporal → FFmpeg | Vorbis |

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

### Guías Rápidas

| Tema | Español | English |
|------|---------|---------|
| Arquitectura | [architecture.md](docs/es/architecture.md) | [architecture.md](docs/en/architecture.md) |
| Pantallas | [screens.md](docs/es/screens.md) | [screens.md](docs/en/screens.md) |
| Pipeline de Audio | [pipeline.md](docs/es/pipeline.md) | [pipeline.md](docs/en/pipeline.md) |
| Configuración | [configuration.md](docs/es/configuration.md) | [configuration.md](docs/en/configuration.md) |
| Testing | [testing.md](docs/es/testing.md) | [testing.md](docs/en/testing.md) |
| Navegación | [routing.md](docs/es/routing.md) | [routing.md](docs/en/routing.md) |
| Internacionalización | [i18n.md](docs/es/i18n.md) | [i18n.md](docs/en/i18n.md) |
| ONNX Runtime | [onnx-runtime.md](docs/es/onnx-runtime.md) | [onnx-runtime.md](docs/en/onnx-runtime.md) |
| Modelo Supertonic 3 | [supertonic-3-model.md](docs/es/supertonic-3-model.md) | [supertonic-3-model.md](docs/en/supertonic-3-model.md) |

### Planes Anteriores

Documentación de fases anteriores del proyecto en [docs/plan/](docs/plan/).

## Licencia

[MIT](LICENSE)

---

<div align="center">

Hecho con ❤️ y Flutter

</div>
