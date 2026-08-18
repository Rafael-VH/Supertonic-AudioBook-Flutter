# Screens

All 8 screens in the application, with responsibilities, state, and navigation.

## Navigation Flow

```
Splash
  └─→ Onboarding (first run)
       └─→ Modelo (download model)
            └─→ Dashboard (main hub)
                 ├─→ Convert (batch conversion)
                 │    └─→ Settings
                 ├─→ Biblioteca (listen to books)
                 └─→ Settings
```

## Screens

### Splash (`/splash`)

**File**: `lib/features/splash/presentation/screens/splash_screen.dart`

Initial loading screen shown while the app initializes.

| State | Display |
|-------|---------|
| Default | Centered logo + app name |

**Navigation**: Auto-navigates to onboarding or dashboard based on first-run detection.

---

### Onboarding (`/onboarding`)

**File**: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

Interactive 5-step guide for first-time users.

| Step | Content |
|------|---------|
| 1 | Download TTS model |
| 2 | Select Markdown files |
| 3 | Choose voice |
| 4 | Process audio |
| 5 | **Select output folder** (new) |

**Key behaviors**:
- Step 5 uses `FilePicker.getDirectoryPath()` to set output folder
- Completing onboarding marks first-run as done
- Skippable via "Skip" button (goes to dashboard)

---

### Dashboard (`/dashboard`)

**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Main hub after onboarding. Shows welcome hero and function cards.

| Card | Action | Target |
|------|--------|--------|
| Convert files | Batch process `.md` folder | `/home` |
| Library | Listen to generated audiobooks | `/biblioteca` |
| Metadata editor | Edit ID3 metadata of MP3 files | `/editor-metadata` |

**Layout**:
- **Mobile** (< 600px): Single column stack
- **Tablet** (≥ 600px): 2-column grid

**Features**:
- Hero section with app description (DASH-8)
- Model status card (isolated, DASH-7)
- Settings gear in AppBar
- Cards use global `cardTheme` with `PaletaExt` accents (DASH-3)

---

### Convert (`/home`)

**File**: `lib/features/convert/presentation/screens/convert_screen.dart`

Batch processing screen — the core of the app.

**Controller**: `HomeController` → `HomeEstado` (in `lib/features/convert/presentation/controllers/`)

#### State (`HomeEstado`)

| Field | Type | Description |
|-------|------|-------------|
| `carpetaIn` | `String` | Input folder path |
| `carpetaOut` | `String` | Output folder path |
| `archivos` | `List<Archivo>` | Found `.md` files |
| `seleccion` | `Set<String>` | Marked file paths (empty = all) |
| `voz` | `String` | Selected voice |
| `steps` | `int` | TTS steps (5–12) |
| `speed` | `double` | Voice speed (0.7–2.0) |
| `langVoz` | `String` | Voice language |
| `formatos` | `Set<String>` | Output formats (wav/mp3/flac/ogg) |
| `ejecutando` | `bool` | Processing in progress |
| `progresoActual` | `int` | Current segment |
| `progresoTotal` | `int` | Total segments |
| `lineasLog` | `List<String>` | Processing log (max 2500 lines) |

#### Sections

1. **Folder selection**: Input/output folder pickers
2. **File list**: `.md` files with checkboxes, select all/none/refresh
3. **Synthesis options**: Voice, steps, speed, language, output formats
4. **Voice preview**: "Listen" button to test voice
5. **Processing**: Progress bar, log, process/cancel buttons

**Responsive layout**:
- **Mobile** (< 900px): Stacked accordion (one section open at a time)
  - Folder sections open by default
  - Animated transitions (fade + slide, 250ms)
- **Tablet** (≥ 900px): Two-column layout (`Row` 50/50)

#### Key behaviors

- Persists preferences before processing (`_guardarPreferencias`)
- Throttles log updates: `paso = max(1, total ~/ 20)`
- Cancels gracefully: exports partial audio, preserves existing files
- Blocks concurrent runs (motor TTS is single-threaded)

---

### Modelo (`/modelo`)

**File**: `lib/features/modelo/presentation/screens/modelo_screen.dart`

Model download and verification screen.

**Controller**: `ModeloController` → `ModeloEstado` (in `lib/features/modelo/presentation/controllers/`)

| State | Display |
|-------|---------|
| Verifying | Spinner while checking disk |
| Downloading | Progress bar + MB + current file + Cancel button |
| Error | Message + Retry button |
| Pending | Size notice + Download button |

**Key behaviors**:
- Resumable downloads
- SHA-256 verification in Isolate
- Model stored in `<app_support>/modelo/`

---

### Settings (`/settings`)

**File**: `lib/features/settings/presentation/screens/settings_screen.dart`

App preferences screen.

**Controller**: `SettingsController` → `SettingsEstado` (in `lib/features/settings/presentation/controllers/`)

| Setting | Widget | Options |
|---------|--------|---------|
| Theme | `SegmentedButton` | Light / Dark |
| Style | `SegmentedButton` | 3 visual variants |
| Language | `SegmentedButton` | Español / English |
| Output folder | Browse button | File picker |

**Key behaviors**:
- Changes persist immediately
- Theme/style changes apply instantly via `AppTheme`
- Output folder affects Convert default path

---

### Biblioteca (`/biblioteca`)

**File**: `lib/features/biblioteca/presentation/screens/biblioteca_screen.dart`

Listen to generated audiobooks.

**Controller**: `BibliotecaController` → `BibliotecaEstado` (in `lib/features/biblioteca/presentation/controllers/`)

| Feature | Description |
|---------|-------------|
| Book grouping | Audios grouped by stem (filename without extension) |
| Format priority | `mp3 > ogg > flac > wav` (BIB-2) |
| Play/pause | Per-tile controls via `ReproductorAudio` contract |
| Empty state | Message + CTA to go to conversion |
| Error state | Message + retry button (BIB-5) |

**Key behaviors**:
- Reproduces only via `ReproductorAudio` contract (never `just_audio` directly, BIB-6)
- Cards inherit global `cardTheme` (DASH-3)
- Error snackbar uses palette error color

---

### Metadata Editor (`/editor-metadata`)

**File**: `lib/features/editor_metadata/presentation/screens/metadata_editor_screen.dart`

ID3 metadata editor for MP3 files.

**Controller**: `MetadataEditorController` (in `lib/features/editor_metadata/presentation/controllers/`)

| Feature | Description |
|---------|-------------|
| File selection | Opens system file picker for MP3 selection |
| Editable fields | Title, artist, album, year, genre, track number |
| Preview | Shows current file metadata |
| Save | Applies changes via `EditorMetadata` contract |

---

## Responsive Layout

### Mobile (< 900px)

- **Convert**: Stacked accordion (one section open at a time)
  - Folder sections open by default
  - Animated transitions (fade + slide, 250ms)
- **Dashboard**: Single column cards

### Tablet (≥ 900px)

- **Convert**: Two-column layout (`Row` 50/50)
- **Dashboard**: 2-column grid (≥ 600px)

### Breakpoints

| Screen | Mobile | Tablet |
|--------|--------|--------|
| Convert | `< 900px` | `≥ 900px` |
| Dashboard | `< 600px` | `≥ 600px` |
