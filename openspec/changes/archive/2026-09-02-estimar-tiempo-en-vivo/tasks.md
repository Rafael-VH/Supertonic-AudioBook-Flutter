# Tasks: Estimación de tiempo en vivo durante conversión

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~60–100 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Estimación viva (estado+math+i18n+render+test) | PR 1 | Single PR; low risk, <400 lines |

## Phase 1: Estado y helper (Foundation)

- [x] 1.1 `home_controller.dart`: add `String? tiempoEstimado` field to `HomeEstado` (constructor optional, `final`, `copyWith` param). RED: none needed (additive field defaults null; 18 existing tests stay green).
- [x] 1.2 `home_controller.dart`: extract `BenchmarkResult? _cargarBenchmark()` (reads `repositorioBenchmarkProvider.cargar()['benchmark_results']`, returns null if not a map or `tamanios.isEmpty`). GREEN. Safety net: reuse in `_mostrarEstimacion` (line 704-708) replaces inline guard — 18 home_controller + 12 benchmark_controller tests green.

## Phase 2: Math vivo en `procesar()` (Core)

- [x] 2.1 RED (`home_controller_test.dart`): seed `benchmark_results` via `PreferenciasMemoria`; `procesar` 2 archivos; assert `tiempoEstimado == t.restante_estimado(seg)` (EVC-2).
- [x] 2.2 GREEN `procesar()`: call `_cargarBenchmark()` once pre-loop; per-file estimate into `estado` before `useCase.procesar` (try/catch `limpiarMarkdown(leerArchivo(ruta)).length`, skip if chars==0 or null benchmark → EVC-1); batch-remaining after each file: `avgReal = elapsed/inicio`, guard `iProcessed>0 && filesRemaining>0`, set `tiempoEstimado = t.restante_estimado(_formatearTiempo(t, avg*filesRemaining))` → EVC-2.
- [x] 2.3 RED `home_controller_test.dart`: no `benchmark_results` se ded; `procesar`; assert `tiempoEstimado` isNull (EVC-3).
- [x] 2.4 RED `home_controller_test.dart`: seed benchmark + `espera/cancelar` a mitad; assert `tiempoEstimado` isNull (EVC-4).
- [x] 2.5 GREEN limpieza: at loop end and on cancel, clear `tiempoEstimado` (EVC-4). Use `clearTiempoEstimado` copyWith flag (copyWith `??` can't null-out).

## Phase 3: i18n

- [x] 3.1 `app_es.arb` + `app_en.arb`: add key `restante_estimado` with `{tiempo}` String placeholder; es "Restante estimado: {tiempo}", en "Estimated remaining: {tiempo}". `app_localizations.dart` regenerated.

## Phase 4: Render (UI)

- [x] 4.1 RED `test/features/convert/presentation/widgets/contenido_registro_test.dart`: add `tiempoEstimado` param to `_estado` helper; pump with value → text renders; null → absent.
- [x] 4.2 GREEN render `tiempoEstimado` line (if != null) in `contenido_registro.dart`, `barra_accion.dart`, `card_registro.dart`.

## Phase 5: Verificación

- [x] 5.1 `flutter analyze` clean; `flutter test` green (strict TDD). Safety net: 18 home_controller + 12 benchmark_controller.
