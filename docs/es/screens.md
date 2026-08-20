# Pantallas

Las 11 pantallas de la aplicación, con responsabilidades, estado y navegación.

## Flujo de Navegación

```
Splash
  └─→ Onboarding (primera ejecución)
       └─→ Dashboard (shell con NavigationBar)
            ├─ Tab Home (hub de funciones)
            │    ├─→ Convert (/home) ─→ Audio Manager (audios pendientes)
            │    └─→ Editor de metadatos
            ├─ Tab Biblioteca (audios generados)
            └─ Tab Settings
                 └─→ Benchmark
```

---

### Splash (`/splash`)

**Archivo**: `lib/features/splash/presentation/screens/splash_screen.dart`

Pantalla de carga inicial. Muestra la marca durante un mínimo de 1.2 s y decide el destino:

| Condición | Destino |
|-----------|---------|
| Primera ejecución (`onboardingVisto == false`) | `/onboarding` |
| Ejecuciones posteriores | `/dashboard` |

---

### Onboarding (`/onboarding`)

**Archivo**: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

Guía interactiva de 5 pasos para usuarios nuevos.

| Paso | Contenido |
|------|-----------|
| 1 | Descargar modelo TTS |
| 2 | Seleccionar archivos Markdown |
| 3 | Elegir voz |
| 4 | Procesar audio |
| 5 | Seleccionar carpeta de salida |

**Comportamientos clave**:
- El paso 5 usa `FilePicker.getDirectoryPath()` y persiste `carpetaSalida`
- Al finalizar marca `onboardingVisto = true` en `preferencias.json` y navega al dashboard
- Se puede saltar (también marca como visto)

---

### Dashboard (`/dashboard`)

**Archivo**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Shell principal con `NavigationBar` de 3 destinos. El contenido alterna con `IndexedStack` (mantiene el estado de cada tab):

| Tab | Contenido | Feature |
|-----|-----------|---------|
| Home | `HomeScreen` — hub de funciones | home |
| Biblioteca | `BibliotecaBody` | biblioteca |
| Settings | `SettingsBody` | settings |

---

### Home — Hub (`tab 0 del dashboard`)

**Archivo**: `lib/features/home/presentation/screens/home_screen.dart`

Hub de bienvenida con cards de función:

| Card | Acción | Destino |
|------|--------|---------|
| Procesar archivos | Bottom sheet: elegir **carpeta** o **archivos `.md`** sueltos | `/home` (Convert) |
| Editor de metadatos | Abrir editor ID3 | `/editor-metadata` |
| Editor de voz | *Próximamente* (deshabilitada) | — |

Al elegir carpeta o archivos, el hub pre-configura el `HomeController` (`setCarpetaIn` / `setModo`) antes de navegar a Convert.

---

### Convert (`/home`)

**Archivo**: `lib/features/convert/presentation/screens/convert_screen.dart`

Pantalla de procesamiento por lotes — el corazón de la app.

**Controller**: `HomeController` → `HomeEstado`

#### Estado (`HomeEstado`)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `carpetaIn` / `carpetaOut` | `String` | Carpetas de entrada/salida |
| `archivos` | `List<Archivo>` | Archivos `.md` cargados |
| `seleccion` | `Set<String>` | Rutas marcadas (vacío = todos) |
| `modoSeleccion` | `SelectionMode` | `carpeta` o `archivos` |
| `voiceConfig` | `VoiceConfig` | Voz, steps (5–12), speed (0.7–2.0), idioma |
| `formatos` | `Set<String>` | Formatos de salida (por defecto `['mp3']`) |
| `ejecutando` / `cancelar` | `bool` | Estado del procesamiento |
| `progresoActual/Total` | `int` | Progreso por segmentos |
| `lineasLog` | `List<String>` | Registro (truncado a 2500 líneas) |
| `pendientes` | `List<AudioPendiente>` | WAVs temporales generados tras procesar |

#### Layout responsive

- **Móvil** (< 900 px): acordeón apilado (`CuerpoApilado`) + barra de acción inferior persistente
- **Tablet** (≥ 900 px): paneles lado a lado (`CuerpoLadoAlado`)

#### Acordeón móvil

| Modo carpeta | Modo archivos |
|--------------|---------------|
| 1. Carpetas | 1. Archivos seleccionados |
| 2. Archivos encontrados | 2. Opciones de síntesis |
| 3. Opciones de síntesis | 3. Registro |
| 4. Registro | |

Una sección abierta a la vez; Carpetas expandida por defecto; transiciones fade+slide (250 ms).

#### Comportamientos clave

- Persiste preferencias antes de procesar
- Pre-chequeo de memoria: si el lote estima > 70 % de RAM disponible, muestra `MemoryWarningDialog`
- Throttle del registro: `paso = max(1, total ~/ 20)`
- Cancelación: exporta lo generado hasta ahora, elimina los temps y no persiste historial
- Bloquea ejecuciones concurrentes (el motor TTS es de un solo hilo)
- Al completar sin errores navega a `/audio-manager` con los audios pendientes

---

### Modelo (`/modelo`)

**Archivo**: `lib/features/modelo/presentation/screens/modelo_screen.dart`

Descarga y verificación del modelo Supertonic 3 (~400 MB).

**Controller**: `ModeloController` → `ModeloEstado`

| Estado | Visualización |
|--------|---------------|
| Verificando | Spinner mientras verifica el disco |
| Descargando | Barra de progreso + MB + archivo actual + Cancelar |
| Error | Mensaje + Reintentar |
| Pendiente | Aviso del tamaño + Descargar modelo |

**Comportamientos clave**: descargas resumibles, verificación SHA-256 en Isolate, almacenamiento en `<app_support>/modelo/`.

---

### Biblioteca (`/biblioteca`, tab 1)

**Archivo**: `lib/features/biblioteca/presentation/screens/biblioteca_screen.dart`

Lista los audios generados en la carpeta de salida.

**Controller**: `BibliotecaController` → `BibliotecaEstado`

| Característica | Descripción |
|----------------|-------------|
| Agrupación | Audios agrupados por stem (nombre sin extensión) |
| Prioridad de formato | `mp3 > ogg > flac > wav` (BIB-2) |
| Play/pausa | Por tile, via contrato `ReproductorAudio` (nunca `just_audio` directo, BIB-6) |
| Refrescar | Botón en AppBar para re-escanear la carpeta |
| Estado vacío | Mensaje + CTA para ir a conversión |
| Estado de error | Mensaje + reintentar (BIB-5) |

---

### Settings (`/settings`, tab 2)

**Archivo**: `lib/features/settings/presentation/screens/settings_screen.dart`

Preferencias de la app, organizadas en cards:

| Sección | Widget | Opciones |
|---------|--------|----------|
| Estado del modelo | `CardEstadoModelo` | Muestra si el modelo está listo + acceso a `/modelo` |
| Tema | `SegmentedButton` | Claro / Oscuro |
| Estilo | `SegmentedButton` | Material / Neumorfismo / Skeuomorfismo |
| Idioma | `SegmentedButton` | Español / English |
| Carpeta de salida | Botón Examinar | Selector de carpetas |
| Benchmark | Card con promedio chars/seg | Botón → `/benchmark` |
| Acerca de | `AcercaDeSection` | Versión, licencia, créditos del modelo |

Los cambios se persisten y aplican al instante.

---

### Editor de Metadatos (`/editor-metadata`)

**Archivo**: `lib/features/editor_metadata/presentation/screens/metadata_editor_screen.dart`

Editor de tags ID3 para archivos MP3.

**Controller**: `MetadataEditorController`

| Característica | Descripción |
|----------------|-------------|
| Selección de archivo | Selector del sistema (MP3) |
| Campos editables | Título, artista, álbum, año, género, pista, disco, comentario, carátula |
| Género | Lista ID3v1 (`id3v1_genres.dart`) |
| Guardar | Via contrato `EditorMetadata` (`EditorMetadataId3Codec`) |

---

### Benchmark (`/benchmark`)

**Archivo**: `lib/features/benchmark/presentation/screens/benchmark_screen.dart`

Mide el rendimiento del motor TTS en el dispositivo.

**Controller**: `BenchmarkController` → `BenchmarkEstado`

| Componente | Descripción |
|------------|-------------|
| Info card | Explica las columnas: Tamaño, Tiempo, Chars/seg |
| Tabla fija | 4 columnas × 6 filas (2500–15000 caracteres) |
| Ejecución | Botón play por fila; spinner mientras corre; resto bloqueado |
| Tiempo | Formato `X h - Y min - Z seg` |
| Historial | Conversiones reales: caracteres, segmentos, duración |

Requiere el modelo listo; si no, redirige a `/modelo`.

---

### Audio Manager (`/audio-manager`)

**Archivo**: `lib/features/audio_manager/presentation/screens/audio_manager_screen.dart`

Revisión de audios recién generados antes de publicarlos.

**Controller**: `AudioManagerController` → `AudioManagerEstado`

Recibe la lista de `AudioPendiente` como `extra` de go_router (push desde Convert).

| Acción | Comportamiento |
|--------|----------------|
| Renombrar | Editar nombre antes de guardar |
| Elegir carpeta | Selector de destino por audio |
| Guardar (individual o todos) | Mueve el WAV temporal al destino (`renameSync`); sufijo `(N)` si existe conflicto de nombre |
| Cancelar/descartar | Elimina los WAVs temporales |

Los WAVs viven en `<carpeta_salida>/_temp/`. Al arrancar la app, `LimpiarTemporales` borra temps con más de 24 h.

---

## Layout Responsive

| Pantalla | Móvil | Tablet |
|----------|-------|--------|
| Convert | `< 900 px`: acordeón + barra inferior | `≥ 900 px`: paneles lado a lado |
| Dashboard | NavigationBar (todas las dimensiones) | — |
