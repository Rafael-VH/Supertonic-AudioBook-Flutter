# Proposal: Benchmark Motor TTS

## Intent

Add a TTS benchmark/calibration module that synthesizes Lorem ipsum text at controlled sizes (1500–15000 chars) to measure device-specific TTS performance. Results are stored in the existing preferences JSON and used to estimate processing time before the user starts a conversion. During normal processing, per-file metrics (segment count, audio duration) are tracked and fed back into the estimation model. The feature surfaces in Settings as a new card, with a dedicated screen showing progress and historical results.

## Scope

### In Scope
- `RunBenchmark` use case in domain layer (depends only on `MotorTts` + `VoiceConfig`)
- `BenchmarkResult` entity for storing per-size timing data
- `BenchmarkController` (Riverpod Notifier) for screen state
- `BenchmarkScreen` with progress indicator, results table, and re-run button
- Settings card to access the benchmark screen
- Route `/benchmark` in GoRouter
- Persist results in existing `RepositorioPreferencias` JSON under `benchmark_results` key
- Lorem ipsum generator (const string + truncation, no library)
- Per-file metrics: modify `ProcesarArchivo.procesar()` to return segment count + audio duration alongside `ResultadoProceso`
- Show estimated processing time in `HomeController` when files are selected (based on benchmark data + per-file text length)
- i18n strings in `app_es.arb` and `app_en.arb`

### Out of Scope
- Telemetry / device info upload (future change)
- Cloud-based benchmark comparison
- Benchmark charts/graphs (simple table only)
- Automatic re-benchmarking on voice change

## Approach

### 1. Domain Layer

**BenchmarkResult entity** (`lib/features/benchmark/domain/entities/benchmark_result.dart`):
- `Map<int, int> tamanios` — char count → processing time in milliseconds
- `VoiceConfig voiceConfig` — snapshot of voice settings used
- `DateTime fecha` — when benchmark was run
- Serialization to/from `Map<String, Object?>` for JSON persistence

**RunBenchmark use case** (`lib/features/benchmark/domain/use_cases/run_benchmark.dart`):
- Takes `MotorTts`, `VoiceConfig`, and an optional `onProgreso(int paso, int total)` callback
- Generates Lorem ipsum text at 6 sizes: 1500, 3000, 5000, 7500, 10000, 15000 chars
- For each size: segments the text (reuses `segmentarTexto`), synthesizes each segment, measures wall-clock time
- Returns `BenchmarkResult`
- Validates model is loaded before starting (caller responsibility)

**Per-file metrics** — extend `ProcesarArchivo.procesar()` return type:
- Change `Future<ResultadoProceso>` → `Future<ProcesarResultado>`
- `ProcesarResultado` contains: `ResultadoProceso estado`, `int segmentos`, `double duracionAudioSeg`
- The caller (`HomeController`) reads these values and stores them for estimation

### 2. Presentation Layer

**BenchmarkController** (`lib/features/benchmark/presentation/controllers/benchmark_controller.dart`):
- `BenchmarkEstado`: ejecutando, progreso, resultado, error
- Reads current `VoiceConfig` from preferences
- Reads/writes `benchmark_results` key via `RepositorioPreferencias`
- `ejecutar()` method invokes `RunBenchmark`

**BenchmarkScreen** (`lib/features/benchmark/presentation/screens/benchmark_screen.dart`):
- Shows "Run benchmark" button, progress indicator during execution, results table after
- Results table: size → time → chars/second
- Last run date display
- Guard: check model is loaded, redirect to `/modelo` if not

**Settings integration**:
- Add `_SeccionCard` before "Acerca de" with benchmark summary (last run date, chars/sec average)
- Tap navigates to `/benchmark`

**Estimation in HomeController**:
- After benchmark exists, `HomeController.build()` reads results
- When files are selected, estimate time using: `totalChars × (avgMsPerChar from benchmark)`
- Display in the status area before processing starts

### 3. Persistence

Store under `benchmark_results` key in existing JSON:
```json
{
  "benchmark_results": {
    "tamanios": {"1500": 2300, "3000": 4500, ...},
    "voice_config": {"voz": "...", "steps": 32, "speed": 1.0, "langVoz": "es"},
    "fecha": "2026-08-19T12:00:00"
  }
}
```

### 4. i18n

Add strings to both `app_es.arb` and `app_en.arb` for:
- Benchmark card title/description
- Benchmark screen title, button labels, progress, results headers
- Estimated time messages
- Error messages (model not ready, cancelled)

## Files Affected

| File | Change |
|------|--------|
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Return `ProcesarResultado` instead of `ResultadoProceso`; add `ProcesarResultado` class |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Read `ProcesarResultado` fields; store per-file metrics; compute estimate from benchmark |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add benchmark `_SeccionCard` before "Acerca de" |
| `lib/presentation/routing/app_router.dart` | Add `/benchmark` route |
| `lib/presentation/controllers/providers.dart` | Add `benchmarkControllerProvider` |
| `lib/shared/data/repositories/repositorio_preferencias.dart` | No changes (raw `cargar()`/`guardar()` suffices) |
| `lib/presentation/l10n/app_es.arb` | Add benchmark + estimation strings |
| `lib/presentation/l10n/app_en.arb` | Add benchmark + estimation strings |

## New Files

| File | Purpose |
|------|---------|
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | Result entity with serialization |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | Core benchmark logic (pure domain) |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Riverpod Notifier for benchmark state |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Benchmark UI with progress and results |
| `test/features/benchmark/domain/use_cases/run_benchmark_test.dart` | Unit test with fake MotorTts |

## Dependencies

- **Internal**: `MotorTts` contract, `VoiceConfig` entity, `RepositorioPreferencias` contract, `segmentarTexto()` function, `ModeloController.listo` (for model guard)
- **External**: None (no new packages)

## Risks

| Risk | Mitigation |
|------|------------|
| Benchmark takes minutes on slow devices | Show real-time progress per size; allow cancellation; 6 sizes is bounded |
| Model not downloaded when benchmark requested | Check `ModeloController.listo` before starting; redirect to `/modelo` if needed |
| Memory pressure from large text synthesis | Process segments incrementally (same as `ProcesarArchivo`); don't accumulate all audio |
| Estimation inaccuracy for very long texts | Mark as "approximate"; re-benchmark updates the estimate |
| `ProcesarResultado` return type change breaks callers | Only `HomeController.procesar()` calls `procesar()` — single call site, safe to update |

## Rollback Plan

The change is additive. Rollback:
1. Revert `procesar_archivo.dart` return type change (restore `Future<ResultadoProceso>`)
2. Remove `benchmark/` feature directory
3. Remove `/benchmark` route
4. Remove benchmark card from settings
5. Remove i18n strings

No data migration needed — `benchmark_results` key in JSON is simply ignored if absent.

## Estimate

- ~250–350 lines of new code (entity + use case + controller + screen + i18n)
- ~30 lines modified (return type change in `procesar_archivo.dart`, home controller additions, settings card, router, providers)
- **Complexity**: Medium — follows existing patterns closely, no new abstractions
- **PR budget**: ~380 changed lines — within 400-line single-PR budget
