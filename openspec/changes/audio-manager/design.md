# Design: audio-manager

## Overview

Separates synthesis from publication. `ProcesarArchivo` generates WAV temp files
and returns them; the user decides folder, name, and format before saving.

Follows existing patterns: Clean Architecture per feature, Spanish identifiers,
Riverpod Notifier controllers, Equatable entities, contracts in `domain/`.

---

## 1. Entity: `AudioPendiente`

**File:** `lib/features/audio_manager/domain/entities/audio_pendiente.dart`

```dart
class AudioPendiente extends Equatable {
  const AudioPendiente({
    required this.tempPath,
    required this.originalName,
    required this.displayName,
    required this.format,
    required this.durationSec,
    required this.fileSizeBytes,
    required this.chars,
    required this.segments,
    required this.fecha,
  });

  /// Absolute path to the WAV in `_temp/`.
  final String tempPath;

  /// Original .md filename (e.g. 'capitulo1.md').
  final String originalName;

  /// Display name derived from stem (e.g. 'Capitulo 1'). User can rename.
  final String displayName;

  /// Source format requested for this audio.
  final String format;

  /// Duration in seconds (from ProcesarResultado).
  final double durationSec;

  /// File size of the temp WAV in bytes.
  final int fileSizeBytes;

  /// Character count of the plain text processed.
  final int chars;

  /// Number of TTS segments.
  final int segments;

  /// When the audio was synthesized.
  final DateTime fecha;

  @override
  List<Object?> get props => [tempPath];
}
```

Follows `Archivo` / `LibroGenerado` patterns: Equatable, computed properties from
constructors, no dart:io in domain.

---

## 2. Use Cases

### `GuardarAudio`

**File:** `lib/features/audio_manager/domain/use_cases/guardar_audio.dart`

Moves a temp WAV to its final destination. Handles format conversion and name
conflicts.

```dart
class GuardarAudio {
  GuardarAudio({
    required this._exportador,
    required this._fileSystem,
  });

  final ExportadorAudio _exportador;
  final FileSystemContract _fileSystem;

  /// Saves [pendiente] to [destino] (full path without extension).
  ///
  /// If [formato] == 'wav': rename temp → destino.wav.
  /// Otherwise: convert via ExportadorAudio, then delete temp.
  ///
  /// If [destino] already exists: appends " (1)", " (2)", etc.
  Future<String> ejecutar(
    AudioPendiente pendiente, {
    required String destino,
    required String formato,
  }) async { ... }
}
```

**Conflict resolution:** `_resolveConflict` suffixes ` (N)` before the extension.
Returns the final path written.

### `LimpiarTemporales`

**File:** `lib/features/audio_manager/domain/use_cases/limpiar_temporales.dart`

Scans `_temp/` and deletes files older than 24h. Pure filesystem scan, no
business logic.

```dart
class LimpiarTemporales {
  LimpiarTemporales({required this._fileSystem});

  final FileSystemContract _fileSystem;

  /// Deletes orphaned WAVs in [tempDir] older than [maxAge].
  /// Returns count of deleted files.
  int ejecutar(String tempDir, {Duration maxAge = const Duration(hours: 24)}) {
    ...
  }
}
```

### `EstimarMemoria` — pure function, NOT a class

**File:** `lib/features/audio_manager/domain/use_cases/estimar_memoria.dart`

A use case class for a single formula is YAGNI. Top-level function:

```dart
/// Estimates bytes of WAV audio generated from [chars] characters.
///
/// Formula: duration ≈ chars / 15 (chars per second for TTS at default speed),
/// then bytes = duration × sampleRate(16000) × bytesPerSample(2).
int estimarBytesAudio(int chars) {
  final durationSec = chars / 15;
  return (durationSec * 16000 * 2).round();
}

/// Estimates total WAV bytes for a batch of [pendingAudios].
int estimarBytesLote(List<AudioPendiente> pendingAudios) {
  return pendingAudios.fold(0, (sum, a) => sum + a.fileSizeBytes);
}

/// Returns estimated RAM usage as fraction of [totalBytes].
/// e.g. 0.72 means 72% of totalBytes.
double fraccionMemoriaRequerida({
  required int bytesEstimados,
  required int totalBytes,
}) {
  if (totalBytes <= 0) return 1.0;
  return bytesEstimados / totalBytes;
}
```

---

## 3. Changes to `ProcesarArchivo`

### `ProcesarResultado` — add `tempPath`

```dart
class ProcesarResultado {
  const ProcesarResultado({
    required this.estado,
    required this.segmentos,
    required this.duracionAudioSeg,
    required this.caracteres,
    this.tempPath,  // ← NEW: path to temp WAV, null if omitido/error
  });

  // ... existing fields ...

  /// Path to the temp WAV file in _temp/, null if processing did not succeed.
  final String? tempPath;
}
```

### `ProcesarArchivo.procesar()` — return temp, don't destroy it

Two key changes:

1. **Create temp in `_temp/` subdir** instead of `dirSalida`:

```dart
final tempDir = '$dirSalida${sep}_temp';
_fileSystem.createDirectory(tempDir);
final rutaWavTrabajo = _nuevoTemporal(tempDir, 'wav', temporales);
```

2. **Don't delete `rutaWavTrabajo` in finally.** Remove it from `temporales`
   before the cleanup loop. The caller owns its lifecycle:

```dart
} finally {
  // Don't delete rutaWavTrabajo — caller manages it
  for (final temporal in temporales) {
    if (temporal != rutaWavTrabajo) {
      _fileSystem.deleteFile(temporal);
    }
  }
}
```

3. **Return `tempPath`** in the result:

```dart
return ProcesarResultado(
  estado: ResultadoProceso.ok,
  segmentos: segmentos.length,
  duracionAudioSeg: duracionTotal,
  caracteres: textoPlano.length,
  tempPath: rutaWavTrabajo,
);
```

4. **Don't compute `duracionTotal`** from the exported formats anymore.
   The WAV hasn't been exported yet. Use the segment count × avg duration
   or skip duracionAudioSeg (set to 0) since it's informational and we
   can compute it when saving.

Actually — simpler: keep the existing export logic but skip the "publish" phase
(rename from temp to final). The WAV is already written. We just return its path
instead of renaming it to the final destination.

Revised approach (minimal diff):

- **Remove the entire "Fase 2: publicar" loop** and the `_publicar` call.
- **Remove the WAV format from `formatosUnicos` iteration** — we always generate
  the WAV; the user chooses the target format later.
- **Keep `rutaWavTrabajo` alive** after `procesar()` returns.
- **Remove `rutaWavTrabajo` from `temporales`** before finally cleanup.

This means `procer()` now only:
1. Reads/cleans markdown
2. Segments text
3. Synthesizes → writes WAV to `_temp/`
4. Returns `tempPath` pointing to that WAV

The conversion to mp3/ogg/flac and the final rename happen in `GuardarAudio`.

---

## 4. Changes to `HomeController`

### After processing: navigate to AudioManagerScreen

Replace the "done" snackbar with navigation to the pending audios screen:

```dart
// In the processing loop, accumulate AudioPendiente list:
final pendientes = <AudioPendiente>[];

for (var i = 0; i < totalArchivos; i++) {
  // ... existing processing ...
  final resultado = await useCase.procesar(...);
  if (resultado.estado == ResultadoProceso.ok && resultado.tempPath != null) {
    pendientes.add(AudioPendiente(
      tempPath: resultado.tempPath!,
      originalName: archivo.nombre,
      displayName: archivo.titulo,
      format: formatos.first,
      durationSec: resultado.duracionAudioSeg,
      fileSizeBytes: _fileSize(resultado.tempPath!),
      chars: resultado.caracteres,
      segments: resultado.segmentos,
      fecha: DateTime.now(),
    ));
  }
}

// After loop: store pending audios in state, navigate
state = state.copyWith(ejecutando: false, pendientes: pendientes);
// Navigation handled by the screen via ref.listen
```

Add `pendientes` field to `HomeEstado`:

```dart
final List<AudioPendiente> pendientes;
```

The screen listens for `pendientes` becoming non-empty and pushes to
`/audio-manager` with the list as extra.

### Memory pre-check

Before the processing loop, estimate memory and show dialog if >70%:

```dart
final totalChars = seleccion.fold(0, (sum, a) => sum + a.nombre.length * 50);
final estimatedBytes = estimarBytesLote(...); // or from chars
final memInfo = ...; // Platform virtual memory
if (estimatedBytes / memInfo > 0.7) {
  // Show MemoryWarningDialog (await)
  // User can cancel
}
```

The memory estimation is rough — use `Platform.environment` or a platform
channel for available RAM. On desktop this is reliable; on mobile, use the
existing `topeMovilBytes` as a proxy.

---

## 5. AudioManagerScreen

**File:** `lib/features/audio_manager/presentation/screens/audio_manager_screen.dart`

Follows `BibliotecaScreen` pattern: Scaffold + AppBar + ConsumerWidget.

```dart
class AudioManagerScreen extends ConsumerWidget {
  const AudioManagerScreen({super.key, required this.pendientes});

  final List<AudioPendiente> pendientes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.audio_manager_titulo)),
      body: _AudioManagerBody(pendientes: pendientes),
      bottomNavigationBar: _SaveAllBar(pendientes: pendientes),
    );
  }
}
```

### Per-tile UI

```
┌─────────────────────────────────────┐
│ 📄 Capitulo 1                      │  ← displayName
│ WAV · 45.2s · 12.3 MB · 3200 chars│  ← format · duration · size · chars
│                         [⋯ More ]  │  ← PopupMenuButton
└─────────────────────────────────────┘
```

More menu options:
- **Elegir carpeta** → folder picker, sets destination
- **Renombrar** → text field dialog
- **Guardar** → save with current settings (destination + format)
- **Eliminar** → delete temp, remove from list

### Bottom bar: "Save All"

Saves all pending audios with a shared format and destination folder.
Shows progress as each file is saved.

---

## 6. `AudioManagerController`

**File:** `lib/features/audio_manager/presentation/controllers/audio_manager_controller.dart`

```dart
class AudioManagerEstado {
  const AudioManagerEstado({
    this.pendientes = const [],
    this.guardando = false,
    this.progresoActual = 0,
    this.progresoTotal = 0,
  });

  final List<AudioPendiente> pendientes;
  final bool guardando;
  final int progresoActual;
  final int progresoTotal;

  bool get vacio => pendientes.isEmpty;

  AudioManagerEstado copyWith({ ... }) { ... }
}

class AudioManagerController extends Notifier<AudioManagerEstado> {
  @override
  AudioManagerEstado build() => const AudioManagerEstado();

  void setPendientes(List<AudioPendiente> pendientes) {
    state = state.copyWith(pendientes: pendientes);
  }

  Future<void> guardarUno(
    AudioPendiente pendiente, {
    required String destino,
    required String formato,
  }) async { ... }

  Future<void> guardarTodos({
    required String destino,
    required String formato,
  }) async { ... }

  void eliminar(String tempPath) { ... }

  void actualizarNombre(String tempPath, String nuevoNombre) { ... }
}
```

Provider:

```dart
final audioManagerControllerProvider =
    NotifierProvider<AudioManagerController, AudioManagerEstado>(
      AudioManagerController.new,
    );
```

---

## 7. Temp File Strategy

### Directory structure

```
carpetaOut/
├── _temp/
│   ├── capitulo1_1692000000000.wav
│   └── capitulo2_1692000001000.wav
├── Capitulo 1.mp3
└── Capitulo 2.mp3
```

### Naming

`{stem}_{microsecondsSinceEpoch}.wav` — same pattern as current `_nuevoTemporal`,
but rooted in `_temp/` subdirectory.

### Cleanup triggers

1. **App startup:** `LimpiarTemporales.ejecutar()` on `_temp/` (files >24h).
   Called from `main.dart` composition or `HomeController.build()`.

2. **After save:** `GuardarAudio` deletes the temp after successful move.

3. **On cancel:** HomeController deletes all temps from the current batch.

### Orphan detection

Files in `_temp/` with `.wav` extension and `lastModified` > 24h ago.
Simple filesystem scan via `FileSystemContract`. No persistence needed.

---

## 8. Providers (additions to `providers.dart`)

```dart
final guardarAudioProvider = Provider<GuardarAudio>((ref) {
  return GuardarAudio(
    exportador: ref.watch(exportadorAudioProvider),
    fileSystem: ref.watch(fileSystemProvider),
  );
});

final limpiarTemporalesProvider = Provider<LimpiarTemporales>((ref) {
  return LimpiarTemporales(
    fileSystem: ref.watch(fileSystemProvider),
  );
});
```

No new contracts needed. `GuardarAudio` uses existing `ExportadorAudio` and
`FileSystemContract`.

---

## 9. Routing

Add to `Rutas`:

```dart
static const audioManager = '/audio-manager';
```

Add route in `appRouterProvider`:

```dart
GoRoute(
  path: Rutas.audioManager,
  builder: (_, state) {
    final pendientes = state.extra as List<AudioPendiente>? ?? [];
    return AudioManagerScreen(pendientes: pendientes);
  },
),
```

---

## 10. Data Flow (end-to-end)

```
User taps "Escuchar" (process)
  → HomeController.procesar()
    → Memory pre-check (estimarMemoria)
    → If >70%: show MemoryWarningDialog → user confirms/cancels
    → For each selected file:
        → ProcesarArchivo.procesar()
        → Writes WAV to carpetaOut/_temp/{stem}_{ts}.wav
        → Returns ProcesarResultado with tempPath
    → Accumulate List<AudioPendiente>
    → Navigate to /audio-manager with list

AudioManagerScreen
  → Shows list of pending audios
  → Per file: More menu → Guardar → GuardarAudio.ejecutar()
    → If format != 'wav': ExportadorAudio.convertirDesdeWav(temp, destino.formato)
    → FileSystemContract.renameFile(temp, destino final)
    → Delete temp
    → Remove from list
  → "Guardar All": batch with shared destination + format
  → When list empty: auto-navigate back to /home or /biblioteca
```

---

## 11. File Manifest

| File | Action | Description |
|------|--------|-------------|
| `lib/features/audio_manager/domain/entities/audio_pendiente.dart` | **New** | `AudioPendiente` entity |
| `lib/features/audio_manager/domain/use_cases/guardar_audio.dart` | **New** | Move temp → final, handle conflicts |
| `lib/features/audio_manager/domain/use_cases/limpiar_temporales.dart` | **New** | Delete orphaned temps >24h |
| `lib/features/audio_manager/domain/use_cases/estimar_memoria.dart` | **New** | Pure functions for RAM estimation |
| `lib/features/audio_manager/presentation/screens/audio_manager_screen.dart` | **New** | List screen with per-file actions |
| `lib/features/audio_manager/presentation/controllers/audio_manager_controller.dart` | **New** | State management for pending list |
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | **Modify** | Add `tempPath` to result; temp in `_temp/`; skip publish phase |
| `lib/features/convert/presentation/controllers/home_controller.dart` | **Modify** | Accumulate pendientes; navigate after processing; memory pre-check |
| `lib/presentation/controllers/providers.dart` | **Modify** | Add `guardarAudioProvider`, `limpiarTemporalesProvider` |
| `lib/presentation/routing/app_router.dart` | **Modify** | Add `/audio-manager` route + `Rutas.audioManager` |

---

## 12. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Temp WAVs not cleaned on crash | App startup cleanup (LimpiarTemporales, >24h) |
| Name conflict on save | `_resolveConflict` appends (N) suffix |
| Memory pressure from many temps | Temp WAVs are on disk, not in RAM. The WAV is a file, not a buffer |
| Regression in existing flow | `ProcesarResultado.tempPath` is nullable; old callers ignore it. Tests pass unchanged |
| Large batch save blocks UI | `guardarTodos` runs async with progress updates in state |
