# Configuración

Constantes técnicas, preferencias y configuración en tiempo de ejecución.

## Constantes Técnicas

### Configuración del Pipeline (`data/config.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `silenceDurationSecs` | `0.6` | Segundos de silencio entre fragmentos |
| `silenceSamples` | `26460` | Muestras a 44100 Hz × 0.6s |
| `memoriaSafeMarginBytes` | `524288000` | Umbral de RAM para desktop (500 MB) |
| `memoriaSafeMarginBytesMovil` | `67108864` | Umbral de RAM para móvil (64 MB) |
| `subtiposAudio` | Map | Subtipos de audio por formato |

### Valores por Defecto del Producto (`domain/constants/producto.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `defaultVoice` | `'M1'` | Modelo de voz por defecto |
| `defaultLang` | `'es'` | Idioma de síntesis por defecto |
| `defaultTtsSteps` | `5` | Pasos de inferencia TTS por defecto (5–12) |
| `defaultSpeed` | `1.1` | Velocidad de habla por defecto (0.7–2.0) |

### Configuración de Segmentos (`domain/use_cases/segmentar_texto.dart`)

| Constante | Valor | Descripción |
|-----------|-------|-------------|
| `maxCharsPerSegment` | `1500` | Máximo de caracteres por fragmento TTS |
| `mergeThreshold` | `200` | Párrafos más cortos que este se fusionan con el siguiente |

### Formatos Soportados (`domain/use_cases/formato.dart`)

```dart
const formatosNativos = ['wav', 'flac', 'ogg', 'mp3'];
```

## Voces

### Voces Disponibles

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
- **Persistencia**: Paquete `shared_preferences`

### Claves de Preferencia

| Clave | Tipo | Por defecto | Descripción |
|-------|------|-------------|-------------|
| `tema_oscuro` | `bool` | `false` | Modo oscuro habilitado |
| `estilo` | `String` | `'default'` | Variante de estilo visual |
| `idioma` | `String` | `'es'` | Idioma de la interfaz |
| `carpeta_in` | `String` | `<base>/archivos` | Ruta de carpeta de entrada |
| `carpeta_out` | `String` | `<base>/audio` | Ruta de carpeta de salida |
| `voz` | `String` | `'M1'` | Voz seleccionada |
| `steps` | `int` | `5` | Pasos TTS (5–12) |
| `speed` | `double` | `1.1` | Velocidad de habla (0.7–2.0) |
| `lang_voz` | `String` | `'es'` | Idioma de la voz |
| `formatos` | `List<String>` | `['wav', 'mp3']` | Formatos de salida |

### Flujo de Persistencia

```
1. App inicia → HomeController.build() carga desde prefs
2. Usuario cambia ajuste → controller actualiza estado
3. Antes de procesar → _guardarPreferencias() persiste todo
4. Pantalla settings → SettingsController._persistir() en cada cambio
```

## Estructura de Directorios

### Rutas en Tiempo de Ejecución

```
<app_documents>/
├── preferencias.json          # Preferencias del usuario
├── archivos/                  # Carpeta de entrada por defecto
└── audio/                     # Carpeta de salida por defecto

<app_support>/
└── modelo/
    ├── onnx/                  # Archivos de modelo ONNX
    └── voice_styles/          # JSONs de estilos de voz
```

### Detección de Plataforma

Decidido en `main.dart` (composition root):

```dart
esMovil: Platform.isAndroid || Platform.isIOS,
```

Esto afecta:
- Umbral de memoria (64 MB móvil vs 500 MB desktop)
- Layout de UI (acordeón vs columnas)

## Configuración del Modelo

### Modelo Supertonic 3

| Propiedad | Valor |
|-----------|-------|
| Tamaño | ~400 MB |
| Almacenamiento | `<app_support>/modelo/` |
| Resumible | Soportado (Dio) |
| Verificación | SHA-256 en Isolate |

### Archivos del Modelo

```
modelo/
├── onnx/
│   └── model.onnx             # Pesos del modelo TTS
└── voice_styles/
    ├── M1.json                # Voz masculina 1
    ├── M2.json                # Voz masculina 2
    ├── ...
    └── F5.json                # Voz femenina 5
```

## Configuración de Formatos de Audio

### WAV

- **Formato**: PCM 16-bit
- **Frecuencia de muestreo**: 44100 Hz
- **Canales**: Mono
- **Método**: `wav_io.dart` (Dart nativo)

### Formatos FFmpeg

| Formato | Codec | Método |
|---------|-------|--------|
| MP3 | MPEG Layer III | `ffmpeg_kit` |
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
