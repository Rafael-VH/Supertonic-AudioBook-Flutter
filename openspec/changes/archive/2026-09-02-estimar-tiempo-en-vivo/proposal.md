# Proposal: Estimar tiempo en vivo durante conversión

## Intent

Make conversion time predictable while it runs. During `procesar()`, show a LIVE estimate (per-file + self-correcting batch-remaining) reusing the pure `estimarTiempo` already shown post-conversion. Only surface when a `benchmark_results` map exists; otherwise stay silent.

## Scope

### In Scope
- `HomeEstado.tiempoEstimado` (`String?` preformatted) + constructor / `copyWith` / initial-value touch points.
- In `procesar()`: pre-read chars via `limpiarMarkdown(repositorioArchivos.leerArchivo(ruta)).length` (try/catch), per-file estimate via `estimarTiempo`, and batch-remaining (`avgReal_processed × files_remaining`) from existing `inicio` + loop counter.
- Extract tiny `_cargarBenchmark()` helper (returns null when absent) reused by new live path and existing `_mostrarEstimacion` — root-cause fix, one guard two callers.
- i18n: one key `restante_estimado` in `app_es.arb` + `app_en.arb`, reusing `_formatearTiempo`.
- Render `tiempoEstimado` line on the 3 registro widgets (`barra_accion`, `contenido_registro`, `card_registro`).

### Out of Scope
- Rewrite `estimarTiempo`.
- New dependencies or domain use case for the one-line `remaining = avg × count` (keep inline in controller).
- Touch the benchmark feature itself.

## Capabilities

### New Capabilities
- `estimacion-viva-conversion`: live estimated time (per-file + batch-remaining) shown during conversion, silent when no benchmark.

### Modified Capabilities
- None.

## Approach

- Add `tiempoEstimado` to `HomeEstado`; set it each loop iteration.
- Pre-seam for chars: `limpiarMarkdown(leerArchivo(ruta)).length` in try/catch (mirrors `ProcesarArchivo.procesar`; caracteres only exist post-process).
- Batch-remaining: `(now - inicio) / processed` × `remaining` after first processed file (cancel already breaks the loop).
- Reuse `_mostrarEstimacion` guard via `_cargarBenchmark()`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modified | `HomeEstado.tiempoEstimado`, `procesar()` live math, `_cargarBenchmark()`, update `_mostrarEstimacion` |
| `.../widgets/barra_accion.dart` | Modified | Render `tiempoEstimado` line |
| `.../widgets/contenido_registro.dart` | Modified | Render `tiempoEstimado` line |
| `.../screens/tablet/card_registro.dart` | Modified | Render `tiempoEstimado` line |
| `lib/presentation/l10n/app_es.arb` / `app_en.arb` | Modified | key `restante_estimado` |
| `openspec/specs/estimacion-viva-conversion/spec.md` | New | functional delta (from sdd-spec) |

## Risks

| Risk | Mitigation |
|------|------------|
| `leerArchivo` throws mid-loop | try/catch → skip estimate |
| chars == 0 → misleading 0s | skip estimate when chars == 0 |
| First file avgReal=0 → div-by-zero | batch-remaining only after first processed file |
| No benchmark → noise | `_cargarBenchmark()` null guard, silent |

## Rollback Plan

Revert additive changes: remove `tiempoEstimado`, live math, `_cargarBenchmark`, `restante_estimado` key, widget lines. `benchmark_results` untouched. No data migration.

## Dependencies

- Internal: `estimarTiempo`, `limpiarMarkdown`, `RepositorioArchivos` contract, `RepositorioPreferencias` (`benchmark_results`). External: none.

## Success Criteria

- [ ] Conversion screen shows per-file + batch-remaining estimate live when `benchmark_results` present (widget test); silent without benchmark.
- [ ] `flutter analyze` clean; `flutter test` green (strict TDD).

## Estimate

~60–100 changed lines, < 8 files, risk Low → single PR (no chaining).
