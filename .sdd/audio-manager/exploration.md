# Exploration: audio-manager

## Current State

**Processing flow** (`HomeController.procesar`): Reads .md → `ProcesarArchivo.procesar()` → MotorTts.sintetizar() per segment → accumulates Float32List fragments → flushes to temp WAV when RAM budget exceeded → ExportadorAudio converts to final formats → publishes (renames) to `carpetaOut/titulo.ext`. Processing AND saving are a single atomic step.

**ProcesarResultado**: `estado`, `segmentos`, `duracionAudioSeg`, `caracteres` — NO audio bytes, NO output paths.

**Memory budget**: `ProcesarArchivo.presupuestoMemoria()` is a static pure function (mobile vs desktop). Already injected via `TtsConfig`.

**Key insight**: The codebase already creates a `rutaWavTrabajo` temp file internally. The refactor is to expose this temp path instead of immediately converting and publishing.

## Affected Areas

| File | Why |
|------|-----|
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Split synthesis from export; `ProcesarResultado` gains temp path + metadata |
| `lib/features/convert/presentation/controllers/home_controller.dart` | `procesar()` returns pending audios instead of auto-exporting |
| `lib/features/convert/domain/contracts/exportador_audio.dart` | May need `exportarDesdeTemp()` for user-chosen path |
| `lib/shared/domain/contracts/repositorio_archivos.dart` | Needs file move/rename for final save |
| `lib/presentation/controllers/providers.dart` | New providers for audio manager |

## Recommended Approach: Hybrid (memory-then-spill, expose temp)

Reuses the existing flush-to-disk pattern. Stop after writing the temp WAV. The temp WAV IS the "pending audio". New screen shows pending items, user picks destination, export step runs.

## New Module Structure

```
lib/features/audio_manager/
  domain/
    entities/audio_pendiente.dart        — AudioPendiente entity
    contracts/audio_store.dart           — Hold/release temp audio files
    use_cases/
      sintetizar_pendiente.dart          — Synth → temp WAV, return metadata
      exportar_pendiente.dart            — Temp WAV → user-chosen path
      estimar_memoria.dart               — Pre-check RAM + disk
  data/repositories/audio_store_temp.dart — Temp file management
  presentation/
    controllers/audio_manager_controller.dart
    screens/audios_pendientes_screen.dart
    widgets/audio_pendiente_tile.dart
```

## Data Flow

```
User selects files → Home
                    ↓
  [Memory + disk check: warn if estimated exceeds threshold]
                    ↓
  MotorTts.sintetizar() per segment
                    ↓
  Float32List fragments → flush to temp WAV (existing logic)
                    ↓
  NEW: Return temp WAV path + metadata in ProcesarResultado
                    ↓
  "Audios Pendientes" screen shows list
                    ↓
  User: [Choose folder] [Rename] [Save]
                    ↓
  ExportadorAudio.convertirDesdeWav() to chosen path
  + move WAV to chosen path (if WAV format)
                    ↓
  Remove temp file → appears in Biblioteca
```

## Memory Estimation

Before processing:
- Characters → estimated seconds (~10 chars/sec or benchmark data)
- Seconds → bytes: `seconds × sampleRate × 4 (float32)`
- Compare against available RAM
- Show warning dialog with estimated vs available

## Risks

1. **Temp file cleanup** — orphaned WAVs on crash/kill. Need startup scan + periodic GC.
2. **Disk space** — large books produce large WAVs. Check before processing.
3. **Cancel** — partial WAVs from cancel become "pending" or are discarded.
4. **Rename conflicts** — user renames to existing name. Need conflict resolution.
5. **Multi-format** — export from same source temp WAV to MP3 + WAV.
6. **Mode awareness** — folder mode vs archivos mode must be respected.
