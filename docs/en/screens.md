# Screens

The 11 screens of the application, with responsibilities, state and navigation.

## Navigation Flow

```
Splash
  └─→ Onboarding (first run)
       └─→ Dashboard (NavigationBar shell)
            ├─ Home tab (function hub)
            │    ├─→ Convert (/home) ─→ Audio Manager (pending audios)
            │    └─→ Metadata editor
            ├─ Library tab (generated audios)
            └─ Settings tab
                 └─→ Benchmark
```

---

### Splash (`/splash`)

**File**: `lib/features/splash/presentation/screens/splash_screen.dart`

Initial loading screen. Shows the brand for a minimum of 1.2 s and decides the destination:

| Condition | Destination |
|-----------|-------------|
| First run (`onboardingVisto == false`) | `/onboarding` |
| Subsequent runs | `/dashboard` |

---

### Onboarding (`/onboarding`)

**File**: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

Interactive 5-step guide for new users.

| Step | Content |
|------|---------|
| 1 | Download TTS model |
| 2 | Select Markdown files |
| 3 | Choose voice |
| 4 | Process audio |
| 5 | Select output folder |

**Key behaviors**:
- Step 5 uses `FilePicker.getDirectoryPath()` and persists `carpetaSalida`
- Finishing sets `onboardingVisto = true` in `preferencias.json` and navigates to the dashboard
- Can be skipped (also marks it as seen)

---

### Dashboard (`/dashboard`)

**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Main shell with a 3-destination `NavigationBar`. Content switches via `IndexedStack` (preserves each tab's state):

| Tab | Content | Feature |
|-----|---------|---------|
| Home | `HomeScreen` — function hub | home |
| Library | `BibliotecaBody` | biblioteca |
| Settings | `SettingsBody` | settings |

---

### Home — Hub (`dashboard tab 0`)

**File**: `lib/features/home/presentation/screens/home_screen.dart`

Welcome hub with function cards:

| Card | Action | Destination |
|------|--------|-------------|
| Process files | Bottom sheet: choose **folder** or loose **`.md` files** | `/home` (Convert) |
| Metadata editor | Open ID3 editor | `/editor-metadata` |
| Voice editor | *Coming soon* (disabled) | — |

When folder or files are chosen, the hub pre-configures the `HomeController` (`setCarpetaIn` / `setModo`) before navigating to Convert.

---

### Convert (`/home`)

**File**: `lib/features/convert/presentation/screens/convert_screen.dart`

Batch processing screen — the heart of the app.

**Controller**: `HomeController` → `HomeEstado`

#### State (`HomeEstado`)

| Field | Type | Description |
|-------|------|-------------|
| `carpetaIn` / `carpetaOut` | `String` | Input/output folders |
| `archivos` | `List<Archivo>` | Loaded `.md` files |
| `seleccion` | `Set<String>` | Checked paths (empty = all) |
| `modoSeleccion` | `SelectionMode` | `carpeta` or `archivos` |
| `voiceConfig` | `VoiceConfig` | Voice, steps (5–12), speed (0.7–2.0), language |
| `formatos` | `Set<String>` | Output formats (default `['mp3']`) |
| `ejecutando` / `cancelar` | `bool` | Processing state |
| `progresoActual/Total` | `int` | Per-segment progress |
| `lineasLog` | `List<String>` | Log (truncated to 2500 lines) |
| `pendientes` | `List<AudioPendiente>` | Temp WAVs generated after processing |

#### Responsive layout

- **Mobile** (< 900 px): stacked accordion (`CuerpoApilado`) + persistent bottom action bar
- **Tablet** (≥ 900 px): side-by-side panels (`CuerpoLadoAlado`)

#### Mobile accordion

| Folder mode | File mode |
|--------------|---------------|
| 1. Folders | 1. Selected files |
| 2. Files found | 2. Synthesis options |
| 3. Synthesis options | 3. Log |
| 4. Log | |

One section open at a time; Folders expanded by default; fade+slide transitions (250 ms).

#### Key behaviors

- Persists preferences before processing
- Memory pre-check: if the batch estimates > 70 % of available RAM, shows `MemoryWarningDialog`
- Log throttling: `paso = max(1, total ~/ 20)`
- Cancellation: exports what was generated so far, deletes temps, does not persist history
- Blocks concurrent runs (the TTS engine is single-threaded)
- On success without errors, navigates to `/audio-manager` with the pending audios

---

### Model (`/modelo`)

**File**: `lib/features/modelo/presentation/screens/modelo_screen.dart`

Download and verification of the Supertonic 3 model (~400 MB).

**Controller**: `ModeloController` → `ModeloEstado`

| State | Display |
|--------|---------------|
| Verifying | Spinner while checking disk |
| Downloading | Progress bar + MB + current file + Cancel |
| Error | Message + Retry |
| Pending | Size notice + Download model button |

**Key behaviors**: resumable downloads, SHA-256 verification in an Isolate, storage in `<app_support>/modelo/`.

---

### Library (`/biblioteca`, tab 1)

**File**: `lib/features/biblioteca/presentation/screens/biblioteca_screen.dart`

Lists generated audios from the output folder.

**Controller**: `BibliotecaController` → `BibliotecaEstado`

| Feature | Description |
|----------------|-------------|
| Grouping | Audios grouped by stem (filename without extension) |
| Format priority | `mp3 > ogg > flac > wav` (BIB-2) |
| Play/pause | Per tile, via the `ReproductorAudio` contract (never `just_audio` directly, BIB-6) |
| Refresh | AppBar button to re-scan the folder |
| Empty state | Message + CTA to go to conversion |
| Error state | Message + retry (BIB-5) |

---

### Settings (`/settings`, tab 2)

**File**: `lib/features/settings/presentation/screens/settings_screen.dart`

App preferences, organized in cards:

| Section | Widget | Options |
|---------|--------|----------|
| Model status | `CardEstadoModelo` | Shows whether the model is ready + access to `/modelo` |
| Theme | `SegmentedButton` | Light / Dark |
| Style | `SegmentedButton` | Material / Neumorphism / Skeuomorphism |
| Language | `SegmentedButton` | Español / English |
| Output folder | Browse button | Folder picker |
| Benchmark | Card with avg chars/sec | Button → `/benchmark` |
| About | `AcercaDeSection` | Version, license, model credits |

Changes are persisted and applied instantly.

---

### Metadata Editor (`/editor-metadata`)

**File**: `lib/features/editor_metadata/presentation/screens/metadata_editor_screen.dart`

ID3 tag editor for MP3 files.

**Controller**: `MetadataEditorController`

| Feature | Description |
|----------------|-------------|
| File selection | System file picker (MP3) |
| Editable fields | Title, artist, album, year, genre, track, disc, comment, cover art |
| Genre | ID3v1 list (`id3v1_genres.dart`) |
| Save | Via the `EditorMetadata` contract (`EditorMetadataId3Codec`) |

---

### Benchmark (`/benchmark`)

**File**: `lib/features/benchmark/presentation/screens/benchmark_screen.dart`

Measures TTS engine performance on the device.

**Controller**: `BenchmarkController` → `BenchmarkEstado`

| Component | Description |
|------------|-------------|
| Info card | Explains the columns: Size, Time, Chars/sec |
| Fixed table | 4 columns × 6 rows (2500–15000 characters) |
| Execution | Play button per row; spinner while running; rest locked |
| Time format | `X h - Y min - Z seg` |
| History | Real conversions: characters, segments, duration |

Requires the model to be ready; otherwise redirects to `/modelo`.

---

### Audio Manager (`/audio-manager`)

**File**: `lib/features/audio_manager/presentation/screens/audio_manager_screen.dart`

Review of freshly generated audios before publishing them.

**Controller**: `AudioManagerController` → `AudioManagerEstado`

Receives the list of `AudioPendiente` as a go_router `extra` (pushed from Convert).

| Action | Behavior |
|--------|----------------|
| Rename | Edit name before saving |
| Choose folder | Per-audio destination picker |
| Save (single or all) | Moves the temp WAV to the destination (`renameSync`); `(N)` suffix on name conflict |
| Cancel/discard | Deletes the temp WAVs |

WAVs live in `<output_folder>/_temp/`. At app startup, `LimpiarTemporales` deletes temps older than 24 h.

---

## Responsive Layout

| Screen | Mobile | Tablet |
|----------|-------|--------|
| Convert | `< 900 px`: accordion + bottom bar | `≥ 900 px`: side-by-side panels |
| Dashboard | NavigationBar (all sizes) | — |
