# Tasks: refactor-home-controller

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~190 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single PR |
| Delivery strategy | single-pr |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | History use case (test + impl) | PR 1 | base = main; 50 test + 20 impl lines |
| 2 | Memory use case + controller refactor + providers | PR 1 | same PR; 120 lines |

## Phase 1: History Use Case (RED→GREEN)

- [x] 1.1 **RED** Write `test/features/benchmark/domain/use_cases/registrar_conversion_en_historial_test.dart`: fake in-memory `RepositorioPreferencias`; assert prepend order, cap 100, empty list, merges with existing. Run → fails (missing class).
- [x] 1.2 **GREEN** Create `lib/features/benchmark/domain/use_cases/registrar_conversion_en_historial.dart`: `RegistrarConversionEnHistorial(RepositorioPreferencias)`; `call(List<Map<String,Object?>>)` loads, prepends, caps 100, saves. Run new test → green.
- [x] 1.3 Add `registrarConversionEnHistorialProvider` to `lib/presentation/controllers/providers.dart` (wraps `repositorioHistorialProvider`).
- [x] 1.4 Safety net: run `flutter test` — new use-case test + 16 home + 9 benchmark stay green.

## Phase 2: Memory Use Case (pure orchestrator)

- [x] 2.1 Create `lib/features/audio_manager/domain/use_cases/estimar_memoria_disponible.dart`: `EstimarMemoriaDisponible.call({required List<({int chars})> stubs, required int availableBytes})` → `estimarBytesLote` + `fraccionMemoriaRequerida`, returns `(estimatedBytes, availableBytes, fraccion)`. No dart:io. YAGNI: no test (reuses tested math).
- [x] 2.2 Safety net: run `flutter test` — full suite green (no callers changed yet).

## Phase 3: Controller Refactor (Extract Method, behavior-preserving)

- [ ] 3.1 **Replace inline memory pre-check** (lines 434-466) with `_verificarMemoria(seleccion, context)`: builds `({chars})` stubs, reads `ProcessInfo.currentRss`, calls `EstimarMemoriaDisponible`, keeps >0.7 dialog + cancel path in controller.
- [ ] 3.2 **Replace `_persistirHistorial` body** (lines 683-698) to delegate to `RegistrarConversionEnHistorial` via `ref.read(registrarConversionEnHistorialProvider)`.
- [ ] 3.3 Slim `procesar()` by extracting pre-processing `_loguearConfig(t, ...)` + post-loop `_finalizarCorrida(...)`; pure movement.
- [ ] 3.4 Remove now-unused imports (e.g. `estimar_memoria.dart` primitive math if unused elsewhere; `ConversionEntry` if moved to use case).
- [ ] 3.5 Safety net: run `flutter test` — 16 home_controller tests, 9 benchmark tests, new test all green; run `flutter analyze` clean.

## Phase 4: Verification

- [ ] 4.1 Full `flutter test` + `flutter analyze` pass; `home_controller.dart` < 550 lines, `procesar()` < 150 lines.

## Work-Unit Commits

1. `feat(benchmark): add registrarConversionEnHistorial domain use case + tests` — tasks 1.1-1.4.
2. `refactor(audio-manager): add estimarMemoriaDisponible pure orchestrator` — task 2.1-2.2.
3. `refactor(convert): extract history + memory logic out of HomeController` — tasks 3.1-3.5, 4.1.
