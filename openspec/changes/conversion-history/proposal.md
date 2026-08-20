# Proposal: conversion-history

## Intent

After each TTS conversion, the app logs metrics (`segmentos`, `duracionAudioSeg`) but never persists them — the data is lost when the screen closes. Users also cannot choose benchmark test sizes (hardcoded to 6 sizes). This change adds persistent conversion history and configurable benchmark sizes.

## Scope

### In Scope

- **Conversion metrics persistence**: `ConversionEntry` entity with `caracteres` field, saved to `RepositorioPreferencias` as JSON array (capped at 100 entries).
- **Metrics in ProcesarResultado**: Add `caracteres` field to the result object.
- **Home controller persistence**: Write `ConversionEntry` after each successful conversion in `HomeController`.
- **BenchmarkScreen history table**: Display "Caracteres | Segmentos | Duración" with formatted duration (`Xh - Y min - Z seg`).
- **Configurable benchmark sizes**: Bottom sheet with `FilterChip` multi-selection before running benchmark. Default selection = [1500, 3000, 6000, 9000, 12000, 15000].
- **Parameterize RunBenchmark**: `ejecutar()` accepts `List<int> tamanios` instead of hardcoded list.
- **Dynamic progress bar**: Progress denominator derived from selected size count, not `/6`.
- **l10n strings**: New entries in `app_es.arb` and `app_en.arb`.

### Out of Scope

- Export/share conversion history
- Benchmark result persistence (history is conversion-only)
- Charts or graphs for metrics visualization

## Capabilities

### New Capabilities

- `conversion-history`: Persist and display per-file conversion metrics (caracteres, segmentos, duración) as a scrollable history in BenchmarkScreen, capped at 100 entries.

### Modified Capabilities

None — neither `biblioteca-audiolibros` nor `dashboard` specs are affected.

## Approach

1. Create `ConversionEntry` in `lib/features/benchmark/domain/entities/` with `toMap()`/`fromMap()`.
2. Add `caracteres` to `ProcesarResultado` in `lib/features/convert/domain/use_cases/procesar_archivo.dart`.
3. `HomeController` writes `ConversionEntry` to `RepositorioPreferencias` (key `conversion_history`) after each `ok`.
4. `BenchmarkController` loads history on init; provides `tamaniosSeleccionados` state.
5. `BenchmarkScreen` gets a `FilterChip` bottom sheet and a history table.
6. `RunBenchmark.ejecutar()` takes `List<int> tamanios` parameter.
7. Progress bar denominator = `tamanios.length`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Modified | Add `caracteres` to `ProcesarResultado` |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modified | Persist `ConversionEntry` on success |
| `lib/features/benchmark/domain/entities/` | New | `ConversionEntry` entity with `toMap()`/`fromMap()` |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | Modified | Parameterize `tamanios` in `ejecutar()` |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Modified | Add history state, selected sizes |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Modified | Bottom sheet + history table |
| `lib/presentation/l10n/app_es.arb` / `app_en.arb` | Modified | New strings |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| SharedPreferences JSON corruption on crash during write | Low | Write atomically; cap at 100 entries limits data loss |
| History grows unbounded | None | Hard cap: oldest entries pruned beyond 100 |
| Benchmark size bottom sheet UX confusion | Low | Default selection covers common sizes; chips clearly labeled |

## Rollback Plan

Revert `git revert` the single commit(s). `ConversionEntry` is new code with no migration — removing it restores previous behavior. `ProcesarResultado.caracteres` removal is safe since no existing consumer depends on it yet.

## Dependencies

None.

## Success Criteria

- [ ] Each successful conversion appends a `ConversionEntry` to persistent storage
- [ ] History shows in BenchmarkScreen with formatted duration
- [ ] History caps at 100 entries (oldest pruned)
- [ ] Benchmark bottom sheet allows multi-select of 11 sizes
- [ ] Selected sizes feed into `RunBenchmark.ejecutar()` parameter
- [ ] Progress bar denominator matches selected count, not `/6`
- [ ] All existing tests pass; new unit tests cover `ConversionEntry` serialization and history cap logic
