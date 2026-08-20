# Configuración

Constantes técnicas, preferencias y configuración en tiempo de ejecución.

## Constantes Técnicas

### Configuración del Pipeline (`shared/data/config.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `silenceDurationSecs` | `0.6` | Segundos de silencio entre fragmentos |
| `silenceSamples` | `26460` | Muestras a 44100 Hz × 0.6 s |
| `memoriaSafeMarginBytes` | `524288000` | Presupuesto de RAM desktop (500 MB) |
| `memoriaSafeMarginBytesMovil` | `67108864` | Presupuesto de RAM móvil (64 MB) |
| `subtiposAudio` | Map | Subtipos de audio por formato |

### Valores por Defecto del Producto (`shared/domain/constants/producto.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `defaultVoice` | `'M1'` | Voz por defecto |
| `defaultLang` | `'es'` | Idioma de síntesis por defecto |
| `defaultTtsSteps` | `5` | Pasos de inferencia TTS (rango 5–12) |
| `defaultSpeed` | `1.1` | Velocidad de habla (rango 0.7–2.0) |

### Configuración de Segmentos (`features/convert/domain/use_cases/segmentar_texto.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `maxCharsPerSegment` | `1500` | Máximo de caracteres por fragmento TTS |
| `mergeThreshold` | `200` | Párrafos más cortos que este se fusionan con el siguiente |

### Formatos de Salida

```dart
// features/convert/domain/use_cases/formato.dart
const formatosNativos = ['wav', 'flac', 'ogg', 'mp3'];

// Default del HomeController:
['mp3']
```

## Voces

### Voces Disponibles (`voces`)

| Código | Tipo |
|--------|------|
| `M1`–`M5` | Voces masculinas |
| `F1`–`F5` | Voces femeninas |

### Idiomas Soportados (31 + auto)

| Código | Idioma | Código | Idioma |
|--------|--------|--------|--------|
| `es` | Español | `nl` | Nederlands |
| `en` | English | `pl` | Polski |
| `fr` | Français | `pt` | Português |
| `de` | Deutsch | `ro` | Română |
| `it` | Italiano | `ru` | Русский |
| `ar` | العربية | `sk` | Slovenčina |
| `bg` | Български | `sl` | Slovenščina |
| `cs` | Čeština | `sv` | Svenska |
| `da` | Dansk | `tr` | Türkçe |
| `el` | Ελληνικά | `uk` | Українська |
| `et` | Eesti | `vi` | Tiếng Việt |
| `fi` | Suomi | `hi` | हिन्दी |
| `hr` | Hrvatski | `ja` | 日本語 |
| `hu` | Magyar | `ko` | 한국어 |
| `id` | Bahasa Indonesia | `lt` | Lietuvių |
| `lv` | Latviešu | `na` | Auto (sin idioma) |

## Preferencias de Usuario

### Almacenamiento

- **Ubicación**: `<app_documents>/preferencias.json`
- **Formato**: Pares clave-valor JSON
- **Implementación**: `PreferenciasJsonLocal` (repositorio propio sobre archivo JSON — no usa el paquete `shared_preferences`)

### Claves de Preferencia

| Clave | Tipo | Por defecto | Descripción |
|-------|------|-------------|-------------|
| `tema_oscuro` | `bool` | `false` | Modo oscuro habilitado |
| `estilo` | `String` | `'default'` | Variante de estilo visual |
| `idioma` | `String` | `'es'` | Idioma de la interfaz |
| `onboarding_visto` | `bool` | `false` | Onboarding completado |
| `carpeta_in` | `String` | `<base>/archivos` | Carpeta de entrada |
| `carpeta_out` | `String` | `<base>/audio` | Carpeta de salida |
| `voz` | `String` | `'M1'` | Voz seleccionada |
| `steps` | `int` | `5` | Pasos TTS (5–12) |
| `speed` | `double` | `1.1` | Velocidad de habla (0.7–2.0) |
| `lang_voz` | `String` | `'es'` | Idioma de la voz |
| `formatos` | `List<String>` | `['mp3']` | Formatos de salida |

### Los 3 Archivos JSON

Cada repositorio es una instancia independiente de `PreferenciasJsonLocal`, inyectada en `main.dart`:

| Archivo | Provider | Contenido |
|---------|----------|-----------|
| `preferencias.json` | `repositorioPreferenciasProvider` | Preferencias de usuario y ajustes |
| `benchmark.json` | `repositorioBenchmarkProvider` | Resultados del benchmark por tamaño |
| `historial_conversiones.json` | `repositorioHistorialProvider` | Historial de conversiones (cap 100 entradas, solo lotes completos) |

### Flujo de Persistencia

```
1. App inicia → HomeController.build() carga desde preferencias.json
2. Usuario cambia ajuste → controller actualiza estado (+ persiste en Settings)
3. Antes de procesar → PreferencesPersistence guarda voz/formatos/carpetas
4. Lote completo sin cancelar → historial se agrega a historial_conversiones.json
```

## Estructura de Directorios

### Rutas en Tiempo de Ejecución

```
<app_documents>/
├── preferencias.json              # Preferencias del usuario
├── benchmark.json                 # Resultados del benchmark
├── historial_conversiones.json    # Historial de conversiones
├── archivos/                      # Carpeta de entrada por defecto
└── audio/                         # Carpeta de salida por defecto
    └── _temp/                     # WAVs pendientes de guardar (> 24 h se limpian)

<app_support>/
└── modelo/
    ├── onnx/                      # 4 modelos ONNX + tts.json + unicode_indexer.json
    └── voice_styles/              # F1–F5.json, M1–M5.json
```

### Detección de Plataforma

Decidida en `main.dart` (composition root) via `providers.dart`:

```dart
esMovil: Platform.isAndroid || Platform.isIOS,
```

Esto afecta:
- Presupuesto de memoria (64 MB móvil vs 500 MB desktop)
- Layout de UI (acordeón vs columnas, umbral 900 px de ancho)

## Configuración del Modelo

### Modelo Supertonic 3

| Propiedad | Valor |
|-----------|-------|
| Tamaño total | ~400 MB (15 archivos) |
| Almacenamiento | `<app_support>/modelo/` |
| Resumible | Sí (Dio, header Range) |
| Verificación | SHA-256 (ONNX) · tamaño + parseo (JSONs) |

Ver [supertonic-3-model.md](supertonic-3-model.md) para el detalle de archivos.

## Configuración de Formatos de Audio

### WAV

- **Formato**: PCM 16-bit
- **Frecuencia de muestreo**: 44100 Hz
- **Canales**: Mono
- **Método**: `wav_io.dart` (Dart nativo)

### Formatos FFmpeg

| Formato | Codec | Método |
|---------|-------|--------|
| MP3 | MPEG Layer III | `ffmpeg_kit` (**default**) |
| FLAC | FLAC lossless | `ffmpeg_kit` |
| OGG | Vorbis | `ffmpeg_kit` |

### Mapa de Subtipos

```dart
const subtiposAudio = {
  'wav': 'PCM_16',
  'flac': 'PCM_16',
  'ogg': 'VORBIS',
  'mp3': 'MPEG_LAYER_III',
};
```
