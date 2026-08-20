# Tasks: Audio Manager

## Review Workload Forecast

Estimated changed lines: ~900–1100 (10 new files + 4 modified + tests)
400-line budget risk: High
Chained PRs recommended: Yes
Delivery strategy: ask-on-risk
Chain strategy: pending

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | PR |
|------|------|----|
| 1 | Domain layer + ProcesarArchivo changes | PR 1 |
| 2 | Controller + Routing + Providers + i18n | PR 2 |
| 3 | UI (Screen + Dialogs) | PR 3 |

## Phase 1: Domain Layer (PR 1)

- [ ] 1.1 RED: Test `AudioPendiente` entity — creation, equality, props
- [ ] 1.2 GREEN: Create `lib/features/audio_manager/domain/entities/audio_pendiente.dart` — Equatable entity with `tempPath`, `originalName`, `displayName`, `format`, `durationSec`, `fileSizeBytes`, `chars`, `segments`, `fecha`
- [ ] 1.3 RED: Test `estimarBytesAudio`, `estimarBytesLote`, `fraccionMemoriaRequerida`
- [ ] 1.4 GREEN: Create `lib/features/audio_manager/domain/use_cases/estimar_memoria.dart` — three pure top-level functions
- [ ] 1.5 RED: Test `LimpiarTemporales.ejecutar` — deletes files >24h, preserves recent, handles empty dir
- [ ] 1.6 GREEN: Create `lib/features/audio_manager/domain/use_cases/limpiar_temporales.dart`
- [ ] 1.7 RED: Test `GuardarAudio.ejecutar` — WAV rename, format conversion, conflict `(N)` suffix
- [ ] 1.8 GREEN: Create `lib/features/audio_manager/domain/use_cases/guardar_audio.dart`
- [ ] 1.9 Modify `procesar_archivo.dart`: add `tempPath` to `ProcesarResultado`; WAV in `_temp/`; remove publish loop; exclude `rutaWavTrabajo` from finally cleanup
- [ ] 1.10 Update existing `ProcesarArchivo` tests — verify `tempPath` returned and existing tests pass

## Phase 2: Controller + Wiring (PR 2)

- [ ] 2.1 RED: Test `AudioManagerController` — `setPendientes`, `guardarUno`, `eliminar`, `actualizarNombre`
- [ ] 2.2 GREEN: Create `lib/features/audio_manager/presentation/controllers/audio_manager_controller.dart`
- [ ] 2.3 Add `pendientes` to `HomeEstado`; accumulate in `procesar()` loop; navigate to `/audio-manager`
- [ ] 2.4 Add memory pre-check to `HomeController.procesar()` — `estimarBytesLote` → show dialog if >70% RAM
- [ ] 2.5 Add providers to `providers.dart`: `guardarAudioProvider`, `limpiarTemporalesProvider`, `audioManagerControllerProvider`
- [ ] 2.6 Add route `/audio-manager` to `app_router.dart` — pass `pendientes` via `state.extra`
- [ ] 2.7 Add i18n strings to `app_es.arb` and `app_en.arb`
- [ ] 2.8 Call `LimpiarTemporales` on app startup to clean orphaned WAVs

## Phase 3: UI + Integration (PR 3)

- [ ] 3.1 RED: Widget test `AudioManagerScreen` — list renders, metadata visible, menu actions
- [ ] 3.2 GREEN: Create `lib/features/audio_manager/presentation/screens/audio_manager_screen.dart` — tiles + PopupMenuButton + "Save All" bottom bar
- [ ] 3.3 Create `MemoryWarningDialog` — shows estimated/available RAM, Proceed/Cancel; wire into task 2.4
- [ ] 3.4 Integration test: process → AudioManagerScreen → save → verify temp deleted + file at destination
- [ ] 3.5 Run `flutter test` + `flutter analyze` — all pass, no warnings

## Phase 4: Cleanup

- [ ] 4.1 Verify existing `ProcesarArchivo` tests still pass (proposal success criterion)
- [ ] 4.2 Confirm rollback: revert `procesar_archivo.dart`, `home_controller.dart`, delete `audio_manager/` restores prior state
