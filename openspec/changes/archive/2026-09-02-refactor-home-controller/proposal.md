# Proposal: refactor-home-controller

## Intent

`home_controller.dart` (702 lines) is a god class violating presentation purity: it embeds business policy (history persistence with 100-cap, memory-threshold decision) and directly touches repositories, making the controller a "brain" instead of a translator. Keep behavior identical (20+ tests as safety net), extract the high-value business logic to domain use cases, and slim `procesar()`. Do NOT rewrite the feature (ponytail).

## Scope

### In Scope
- Extract `_persistirHistorial` (prepend + cap 100 + save) into a domain use case so home_controller and benchmark_controller share ONE write-path.
- Extract the memory pre-check orchestration (build stubs, read available memory, threshold >0.7 decision) behind a thin use case that reuses `estimar_memoria.dart`.
- Slim `procesar()` by extracting cohesive sub-methods (config log block, history accumulation, post-loop finalize) — behavior-preserving Extract Method only.
- Add providers for the new use cases in `providers.dart` (composition root).

### Out of Scope
- NOT converting `listarArchivosMd` / `crearCarpetasSiNoExisten` repo calls — no use case exists; wrapping is speculative.
- NOT moving `File(...)` temp-WAV checks / `Platform.pathSeparator` paths — allowed/permitted at presentation layer.
- NOT rewriting `procesar()` logic or changing TTS / navigation behavior.
- NOT adding an interface for a single use case implementation (YAGNI).

## Capabilities

### New Capabilities
None — this is a pure refactor; no new external capability is introduced.

### Modified Capabilities
None — spec-level behavior does not change. Existing `conversion-history` and `memory-estimation` capabilities keep identical behavior; only implementation home changes.

## Approach

1. **New use case `registrar_conversion_en_historial`** in `benchmark/domain/use_cases/`: takes `RepositorioPreferencias` (historial) + list of entries; loads, prepends, caps at 100, saves. Provider in `providers.dart`.
2. **New use case `estimar_memoria_disponible`** (or reuse thin helper) in `audio_manager/domain/use_cases/`: builds stub `AudioPendiente`s from archivos, reads available bytes (via injected provider, NOT direct `ProcessInfo` in the controller), returns `{estimatedBytes, availableBytes, fraccion}`. Keep `estimar_memoria.dart` math as-is. The >0.7 dialog trigger STAYS in the controller (presentation concern).
3. **Refactor `_mostrarEstimacion`** — already delegates to `estimar_tiempo()`; minimal: keep, just move out of god method if it helps cohesion.
4. **Slim `procesar()`** via Extract Method: `_loguearConfig()`, `_finalizarCorrida(...)`. Pure movement, no behavior change.
5. Update `home_controller_test.dart` wiring only if provider shape changes; add targeted tests for the new use cases.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/features/benchmark/domain/use_cases/registrar_conversion_en_historial.dart` | New | History persistence use case (prepend + cap 100) |
| `lib/features/audio_manager/domain/use_cases/estimar_memoria_disponible.dart` | New | Memory pre-check orchestration (reuses estimar_memoria) |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modified | Delegate to new use cases; slims `procesar()`; removes inline history/memory policy |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Modified | Reuse history use case for read/write (drop duplicate inline logic) |
| `lib/presentation/controllers/providers.dart` | Modified | Add providers for new use cases |
| `test/presentation/controllers/home_controller_test.dart` | Modified | Wiring if provider shape changes |
| `test/...` new use-case tests | New | Targeted unit tests |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Behavior drift in history ordering/cap | Med | New use-case unit test asserts prepend + 100 cap; existing home/benchmark tests as safety net |
| Memory pre-check changes threshold behavior | Med | Keep threshold (0.7) and dialog trigger in controller; assert stub char calc preserved |
| `procesar()` extraction breaks state transitions | Low | Behavior-preserving Extract Method; run full home_controller_test.dart after each step |

## Rollback Plan

Pure refactor with additive use cases. Revert = `git revert` the commits; remove the new use-case files/providers; home_controller and benchmark_controller revert to inline logic. `flutter test` must pass before/after.

## Dependencies

- None new. Reuses `estimar_memoria.dart`, `estimar_tiempo.dart`, `ConversionEntry`, `RepositorioPreferencias`.

## Success Criteria

- [ ] `home_controller.dart` drops below ~550 lines, `procesar()` below ~150 lines
- [ ] `_persistirHistorial` and `_mostrarEstimacion` inline caps/thresholds no longer in controller
- [ ] History write logic exists once (used by home + benchmark)
- [ ] `flutter test` passes — no existing test modified except provider-wiring deltas
- [ ] No new speculative wrappers for `listarArchivosMd`/`crearCarpetasSiNoExisten`
