# Tasks: Conversion History

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 250–350 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | size-exception |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Domain Entity (ConversionEntry)

- [ ] 1.1 Create `lib/features/benchmark/domain/entities/conversion_entry.dart` with `ConversionEntry` class (fields: nombreArchivo, caracteres, segmentos, duracionAudioSeg, fecha), `toMap()` and `fromMap()` following `BenchmarkResult` pattern.

## Phase 2: ProcesarResultado — add caracteres

- [ ] 2.1 Add `caracteres` (required int) to `ProcesarResultado` in `lib/features/convert/domain/use_cases/procesar_archivo.dart`. Set `textoPlano.length` in all 4 return sites (error, omitido×2, ok). Error/omitido use `0`.

## Phase 3: RunBenchmark parameterization

- [ ] 3.1 Add `tamanios` param (`List<int>?`) to `RunBenchmark.ejecutar()` in `lib/features/benchmark/domain/use_cases/run_benchmark.dart`. Default to `[1500, 3000, 6000, 9000, 12000, 15000]` when null. Replace `_tamaniosPrueba` reference with local `sizes`. Extend `_lorem` to cover 30000 chars if needed.

## Phase 4: BenchmarkController state updates

- [ ] 4.1 Add `tamaniosDisponibles`, `tamaniosSeleccionados`, `historial` fields to `BenchmarkEstado` in `lib/features/benchmark/presentation/controllers/benchmark_controller.dart`. Update `copyWith()`.
- [ ] 4.2 In `BenchmarkController.build()`, load `conversion_history` from prefs, deserialize to `List<ConversionEntry>`, and set initial `historial`. Pass `tamaniosSeleccionados` to `RunBenchmark.ejecutar()` in `ejecutar()`.

## Phase 5: HomeController persistence

- [ ] 5.1 In `lib/features/convert/presentation/controllers/home_controller.dart`, after `ResultadoProceso.ok`, build a `ConversionEntry` from `resultado` + `archivo.nombre` + `textoPlano.length`, and persist to prefs under `conversion_history` (prepend, cap at 100).

## Phase 6: BenchmarkScreen UI

- [ ] 6.1 Add size selection bottom sheet with `FilterChip` multi-selection to `lib/features/benchmark/presentation/screens/benchmark_screen.dart`. Buttons to run/close. Disable run when 0 selected.
- [ ] 6.2 Add history `DataTable` section (columns: Palabras, Segmentos, Duración). Format duration as `Xh - Y min - Z seg` / `Y min - Z seg` / `Z seg`. Empty state when no history.
- [ ] 6.3 Update progress indicator denominator from hardcoded `6` to `estado.tamaniosSeleccionados.length`.

## Phase 7: i18n strings

- [ ] 7.1 Add new strings to `lib/presentation/l10n/app_es.arb`: benchmark size labels, history headers, duration format, empty history message, size sheet title.
- [ ] 7.2 Add matching English strings to `lib/presentation/l10n/app_en.arb`.

## Phase 8: Tests

- [ ] 8.1 Add `ConversionEntry` roundtrip test (toMap→fromMap equality) in `test/features/benchmark/domain/entities/conversion_entry_test.dart`.
- [ ] 8.2 Add history cap test: 101 entries → oldest pruned, count = 100.
- [ ] 8.3 Add `BenchmarkEstado.copyWith()` test: defaults and overrides for new fields.
- [ ] 8.4 Add `RunBenchmark.ejecutar()` test: custom `tamanios` param only processes those sizes.
- [ ] 8.5 Update `benchmark_controller_test.dart`: verify `historial` loaded from prefs on build, verify `tamaniosSeleccionados` passed to `ejecutar()`.
