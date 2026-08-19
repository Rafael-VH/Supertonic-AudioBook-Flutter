# Tasks: Benchmark Motor TTS

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~480 (350 new + 130 modified) |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single PR — module is cohesive; 400-line guard is a planning estimate, not a hard wall |
| Delivery strategy | pending |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Benchmark module + ProcesarResultado wrapper + integration + i18n + tests | PR 1 | All changes are tightly coupled; single PR with work-unit commits |

## Phase 1: Domain Entity + Serialization

- [x] 1.1 Create `lib/features/benchmark/domain/entities/benchmark_result.dart` — entity with `tamanios`, `voiceConfig`, `fecha`, `toMap`/`fromMap`, `avgMsPerChar`, `avgCharsPerSec` getters. Import `VoiceConfig` from `shared/domain/entities/voice_config.dart`.

## Phase 2: Domain Use Cases (TDD — RED first)

- [x] 2.1 **RED**: Create `test/features/benchmark/domain/use_cases/estimar_tiempo_test.dart` — unit tests: positive estimation, empty benchmark returns null, known avgMsPerChar input. Import `BenchmarkResult` and `estimarTiempo`.
- [x] 2.2 **GREEN**: Create `lib/features/benchmark/domain/use_cases/estimar_tiempo.dart` — pure function `double? estimarTiempo({required BenchmarkResult benchmark, required int textoChars})`. Linear: `textoChars * benchmark.avgMsPerChar / 1000.0`.
- [x] 2.3 **RED**: Create `test/features/benchmark/domain/use_cases/run_benchmark_test.dart` — unit tests with fake `MotorTts`: runs 6 sizes, records timing, cancellation returns partial (no persistence), uses `segmentarTexto()`.
- [x] 2.4 **GREEN**: Create `lib/features/benchmark/domain/use_cases/run_benchmark.dart` — `RunBenchmark(motor, logger)` with `Future<BenchmarkResult> ejecutar(voiceConfig, onProgreso, debeDetenerse)`. Const sizes `[1500,3000,5000,7500,10000,15000]`, const Lorem ipsum ≥15000 chars. Per size: substring → segmentarTexto → motor.sintetizar each segment (discard audio) → stopwatch ms.

## Phase 3: ProcesarResultado Wrapper

- [x] 3.1 Add `ProcesarResultado` class to `lib/features/convert/domain/use_cases/procesar_archivo.dart` (after imports, before `ResultadoProceso` enum). Fields: `estado` (`ResultadoProceso`), `segmentos` (`int`), `duracionAudioSeg` (`double`).
- [x] 3.2 Change `procesar()` return type from `Future<ResultadoProceso>` to `Future<ProcesarResultado>`. Wrap all return points: `ok` → compute `duracionAudioSeg` from existing `_exportador.duracionAudio()` loop; `error`/`omitido` → `ProcesarResultado(estado: ..., segmentos: 0, duracionAudioSeg: 0)`.
- [x] 3.3 Update `lib/features/convert/presentation/controllers/home_controller.dart` — switch on `resultado.estado` (was `resultado` directly); log `resultado.segmentos` and `resultado.duracionAudioSeg` for ok case.

## Phase 4: Presentation Layer

- [x] 4.1 Create `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` — `BenchmarkController extends Notifier<BenchmarkEstado>` with `BenchmarkEstado` state class (ejecutando, pasoActual, tamanioActual, resultado, cancelado, error, copyWith). Methods: `build()` loads from prefs, `ejecutar()`, `cancelar()`, `_cargarResultado()`.
- [x] 4.2 Create `lib/features/benchmark/presentation/screens/benchmark_screen.dart` — `ConsumerWidget` with status card, run/cancel buttons, `LinearProgressIndicator`, results `DataTable`, last-run footer. Check `modeloControllerProvider.listo` on mount → redirect to `/modelo` if false.

## Phase 5: Integration Wiring

- [x] 5.1 Add `benchmarkControllerProvider` to `lib/presentation/controllers/providers.dart` — `NotifierProvider<BenchmarkController, BenchmarkEstado>(BenchmarkController.new)`.
- [x] 5.2 Add `static const benchmark = '/benchmark'` to `Rutas` and `GoRoute` in `lib/presentation/routing/app_router.dart`.
- [x] 5.3 Add benchmark `_SeccionCard` to `lib/features/settings/presentation/screens/settings_screen.dart` before "Acerca de" card — reads provider for summary, button navigates to `Rutas.benchmark`.
- [x] 5.4 Add estimation display to `home_controller.dart` — after processing loop, read `benchmark_results` from prefs, compute `estimarTiempo(benchmark, totalChars)`, log formatted estimate.

## Phase 6: i18n

- [x] 6.1 Add 14 benchmark + estimation strings to `lib/presentation/l10n/app_es.arb` (with `@` metadata for placeholders).
- [x] 6.2 Add corresponding 14 strings to `lib/presentation/l10n/app_en.arb`.

## Phase 7: Controller Tests

- [x] 7.1 Create `test/features/benchmark/presentation/controllers/benchmark_controller_test.dart` — state transitions: idle → ejecutando → resultado, cancel returns to idle, error state, persistence read/write.
