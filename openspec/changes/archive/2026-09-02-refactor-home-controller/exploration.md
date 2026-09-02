# Exploration: refactor-home-controller

## Current structure

`lib/features/convert/presentation/controllers/home_controller.dart` (702 lines) is a `Notifier<HomeEstado>` god class. Responsibilities identified:

1. **Build/initialization** (L139-185): reads prefs, builds default folders/tempate state, lists `.md` files.
2. **Folder + file list management** (L189-289): pick folders, load/replace/merge external files, selection.
3. **Selection ops** (L293-306): toggle/select-all/clear via delegating `SelectionManager`.
4. **Options** (L310-338): voice/steps/speed/lang/format toggles.
5. **Voice preview** `escuchar` (L343-368): delegates to `VoicePreviewService` (already extracted).
6. **`procesar()`** (L383-620, ~237 lines): god method — validation, memory pre-check, TTS loop, history persistence, temp cleanup, estimation, navigation, logging.
7. **Helpers** (L624-698): `_onProgreso`, `_formatearTiempo`, `_appendLog`, `_mostrarEstimacion`, `_persistirHistorial`.

## dart:io uses (audited)

- `Platform.pathSeparator` (L141, L504): simple path assembly — ALLOWED per project rule (presentation can use dart:io; domain cannot).
- `File(...)` (L527, L568): temp WAV existence/size check and temp cleanup — reads UI-level temp artifacts, stays presentation.
- `ProcessInfo.currentRss` (L449): reads available RAM for memory pre-check — genuine business decision input that lives in `audio_manager` domain.

## What already exists to REUSE (verified)

1. **`estimar_memoria.dart`** (`audio_manager/domain/use_cases/`) — already imported by home_controller (L13) and its functions `estimarBytesLote` + `fraccionMemoriaRequerida` are ALREADY called at L448/L450. **No duplication of the estimation math.** What is NOT covered: reading `availableBytes` (platform) and building the pending stubs.
2. **`estimar_tiempo.dart`** (`benchmark/domain/use_cases/`) — `estimarTiempo()` ALREADY called by `_mostrarEstimacion` (L674). **Estimation logic already shared.**
3. **`ConversionEntry`** entity — already exists (`benchmark/domain/entities/`). Home_controller uses `.toMap()` (L525).
4. **`BenchmarkResult.fromMap`** — already exists; used by `_mostrarEstimacion` (L665).

## Gaps (genuine business logic with no home)

1. **History persistence** (`_persistirHistorial`, L683-698): prepend + cap-at-100 + save is duplicated conceptually between `home_controller.dart` and `benchmark_controller.dart` (`_cargarHistorial`, L80-90). The write-path logic lives ONLY in home_controller; no use case/service exists.

2. **Memory pre-check orchestration** (L433-466): building the stub `AudioPendiente` list with `chars = nombre.length * 50`, reading `ProcessInfo.currentRss`, comparing via `fraccionMemoriaRequerida`, and triggering the warning at >0.7. The estimation math is shared; the **available-memory read + threshold decision + stub building** is not.

3. **Direct repo calls**:
   - `ref.watch(repositorioPreferenciasProvider).cargar()` (L139)
   - `ref.read(repositorioArchivosProvider).listarArchivosMd(...)` (L157, L234)
   - `ref.read(repositorioArchivosProvider).crearCarpetasSiNoExisten([...])` (L471)
   
   No use cases exist for listing `.md` files or creating folders. Wrapping them would be speculative (ponytail: skip).

## Decision framing (ponytail)

High-value, behavior-preserving extractions ONLY:

| Extraction | Existing use case? | Action |
|-----------|-------------------|--------|
| Memory estimation math | YES (estimar_memoria) | Already reused — keep |
| Time estimation | YES (estimar_tiempo) | Already reused — keep |
| History persistence (read/write+cap) | NO | Create ONE use case, reuse in both home + benchmark controllers |
| Memory pre-check (available read + threshold + stub build) | Partial | Minor: keep available-memory read local OR create thin helper |
| listarArchivosMd / crearCarpetasSiNoExisten | NO | Skip (speculative wrapper) — keep direct |

Safety net: `test/presentation/controllers/home_controller_test.dart` (~20 tests) + benchmark controller tests.
