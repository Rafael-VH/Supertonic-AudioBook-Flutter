# Design: refactor-home-controller

## Executive Summary

Behavior-preserving refactor of the 702-line `HomeController` god class. Extract two domain use cases (history persistence + memory estimation), slim `procesar()` via Extract Method. Zero new abstractions, zero interface-with-one-implementation. All 20+ existing tests remain the safety net.

## Architecture Decisions

### Decision: Memory estimate input (the fork)

**Choice**: Option (b) — controller reads `ProcessInfo.currentRss` and passes `availableBytes` as a parameter to the pure use case.

**Alternatives considered**:
- (a) Inject a "read available memory" function/provider into the use case.

**Rationale**: Ponytail + arquiman. The use case is a pure math function: `fraccionMemoriaRequerida(estimatedBytes, availableBytes)`. It already exists in `estimar_memoria.dart`. Adding a function-provider for a single platform call is YAGNI. The controller already uses `dart:io` per project rule. The threshold dialog trigger (>0.7) stays in the controller because it's presentation behavior. Zero new abstractions.

### Decision: History use case placement

**Choice**: `lib/features/benchmark/domain/use_cases/registrar_conversion_en_historial.dart`.

**Rationale**: The `ConversionEntry` entity and `repositorioHistorialProvider` already live under `benchmark/`. The use case belongs where its domain concept lives. Both `home_controller` and `benchmark_controller` import from benchmark domain — no new cross-feature dependency.

### Decision: Memory orchestration reuse

**Choice**: Create `estimar_memoria_disponible.dart` as a thin orchestrator in `audio_manager/domain/use_cases/` that reuses the existing `estimarBytesLote`/`fraccionMemoriaRequerida` from `estimar_memoria.dart`. The controller builds a lightweight `({int chars})` list (not `AudioPendiente` objects) to avoid domain→presentation coupling.

**Rationale**: The orchestration (build stub list → estimate → return triple) is business logic that should live in domain. The existing math functions stay untouched. No dart:io, no AudioPendiente dependency.

## Data Flow

```
procesar()
  ├─ _persistirHistorial(historialPendiente)
  │    └─ RegistrarConversionEnHistorial → repositorioHistorialProvider
  │
  └─ _verificarMemoria(seleccion, context)
       ├─ Build ({chars}) stubs from Archivo list (presentation, allowed)
       ├─ Call estimarMemoriaDisponible() from audio_manager/domain
       │    └─ Reuses estimarBytesLote + fraccionMemoriaRequerida
       ├─ Read ProcessInfo.currentRss (dart:io, presentation, allowed)
       ├─ If fraccion > 0.7 → show memory warning dialog
       └─ Return bool (proceed or cancel)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/benchmark/domain/use_cases/registrar_conversion_en_historial.dart` | **Create** | Pure use case: prepend entries to history, cap at 100, save via `RepositorioPreferencias` |
| `lib/features/audio_manager/domain/use_cases/estimar_memoria_disponible.dart` | **Create** | Pure orchestrator: takes stubs list + availableBytes → returns `(estimatedBytes, availableBytes, fraccion)`. Reuses `estimarBytesLote` + `fraccionMemoriaRequerida` |
| `lib/features/convert/presentation/controllers/home_controller.dart` | **Modify** | Extract `_verificarMemoria()` + `_persistirHistorial()`. Delete inline history logic. Slim `procesar()` by ~80 lines |
| `lib/presentation/controllers/providers.dart` | **Modify** | Add `registrarConversionEnHistorialProvider` |
| `test/features/benchmark/domain/use_cases/registrar_conversion_en_historial_test.dart` | **Create** | Unit tests: prepend order, cap 100, empty list, merges with existing |

### New Use Case Signatures

```dart
// registrar_conversion_en_historial.dart
class RegistrarConversionEnHistorial {
  RegistrarConversionEnHistorial(this._repo);
  final RepositorioPreferencias _repo;

  /// Prepend [entradas] to conversion_history, cap at 100, save.
  void call(List<Map<String, Object?>> entradas) { ... }
}

// estimar_memoria_disponible.dart
class EstimarMemoriaDisponible {
  /// Returns (estimatedBytes, availableBytes, fraccion).
  ({int estimatedBytes, int availableBytes, double fraccion})
  call({
    required List<({int chars})> stubs,
    required int availableBytes,
  }) { ... }
}
```

## What Stays in the Controller (per proposal)

- `ProcessInfo.currentRss` read (dart:io, presentation-legal)
- 0.7 threshold + `showMemoryWarningDialog` trigger
- Temp-WAV file checks (`File(...).existsSync()`)
- Path assembly (`Platform.pathSeparator`)
- `_loguearConfig()` / `_finalizarCorrida()` (Extract Method helpers, still presentation)

## Benchmark Controller Adoption

`benchmark_controller.dart` **reads** history via `_cargarHistorial()` (lines 80-90) but **never writes** to it — only `home_controller` writes. The shared `RegistrarConversionEnHistorial` use case is available if benchmark_controller ever needs to write, but no change to benchmark_controller is needed now. Its 9 existing tests pass without modification.

## Dependency Direction (arquiman-clean)

```
presentation (home_controller)
  └─→ domain/use_cases/registrar_conversion_en_historial
        └─→ shared/domain/contracts/repositorio_preferencias  ✅

presentation (home_controller)
  └─→ domain/use_cases/estimar_memoria_disponible
        └─→ domain/use_cases/estimar_memoria (same feature)  ✅
```

No `domain/` imports `presentation/`. No `shared/` imports `features/`. `dart:io` stays in presentation only.

## Test Plan

### Existing Safety Net (no changes needed)

- `test/presentation/controllers/home_controller_test.dart` — 16 tests. All must stay green.
- `test/features/benchmark/presentation/controllers/benchmark_controller_test.dart` — 9 tests. All must stay green.

### New Unit Tests

| Test File | What to Test | Approach |
|-----------|-------------|----------|
| `test/features/benchmark/domain/use_cases/registrar_conversion_en_historial_test.dart` | Prepend order, cap at 100, empty list, merges with existing entries | Fake `RepositorioPreferencias` (in-memory) — pure domain test, no mocks needed |

**TDD order**: Write `registrar_conversion_en_historial_test.dart` RED → implement use case GREEN → wire into controller → run existing test suite GREEN.

### No New Tests Needed For

- `estimar_memoria_disponible.dart` — it's a 3-line pure function wrapping existing tested math. YAGNI on test until the math changes.
- `_verificarMemoria` / `_persistirHistorial` extraction — these are Extract Method refactors of existing tested behavior. The existing 16 tests cover them.

## Out of Scope (per proposal)

- `listarArchivosMd` / `crearCarpetasSiNoExisten` wrapping — speculative, no use case
- Moving `File()` / `pathSeparator` — allowed at presentation
- Rewriting `procesar()` logic — behavior-preserving only
- Interface for single implementation — YAGNI
- Converting `BenchmarkController` history reads — already clean, no duplication to fix

## Changed-Line Estimate + Risk

| Metric | Estimate |
|--------|----------|
| New lines (2 use case files) | ~60 |
| New test lines | ~50 |
| Modified lines (controller + providers) | ~80 net (remove ~100 inline, add ~20 extracted methods) |
| **Total changed lines** | **~190** |
| 400-line PR budget risk | **Low** |
| Risk | **Low** — pure refactor, additive use cases, all existing tests as safety net |
