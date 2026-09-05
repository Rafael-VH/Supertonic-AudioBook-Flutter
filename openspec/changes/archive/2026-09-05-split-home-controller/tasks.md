# Tasks: split-home-controller

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~240 |
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
| F1 | Relocar `memory_warning_dialog` a `core/widgets/` | PR 1 | git mv + import + test movido; 0 lógica |
| F2 | Extract Method `_procesarLote` del loop de `procesar()` | PR 1 | movimiento puro; suite verde |
| F3 | Evento `advertenciaMemoria` + vista muestra el diálogo | PR 1 | TDD: widget test RED → GREEN; `rssProcesoProvider` |

## Phase 1: F1 — Relocar `memory_warning_dialog` (mecánico)

- [x] 1.1 **MOVE** `git mv lib/features/audio_manager/presentation/screens/memory_warning_dialog.dart lib/core/widgets/memory_warning_dialog.dart`.
- [x] 1.2 **MOVE TEST** `git mv test/features/audio_manager/presentation/screens/memory_warning_dialog_test.dart test/core/widgets/memory_warning_dialog_test.dart`.
- [x] 1.3 Actualizar el import en `lib/features/convert/presentation/controllers/home_controller.dart:15` → `core/widgets/memory_warning_dialog.dart`.
- [x] 1.4 Actualizar el import del test movido si referencia la ruta vieja.
- [x] 1.5 Verificación: `flutter test test/core/widgets/memory_warning_dialog_test.dart test/presentation/controllers/home_controller_test.dart` → verde.

## Phase 2: F2 — Extract Method `_procesarLote`

- [x] 2.1 **REFACTOR** Extraer el `for (var i = 0; i < totalArchivos; i++) { ... }` (`home_controller.dart:465-552`) a un método privado `_procesarLote` que recibe por parámetro `(t, seleccion, salida, steps, speed, formatos, lang, inicio, benchmark)` y muta por referencia `acumulados`/`historialPendiente`, devolviendo `(exitos, errores, procesados)`. Movimiento puro: mismas variables capturadas, mismo orden, mismos logs.
- [x] 2.2 Verificación: `flutter test test/presentation/controllers/home_controller_test.dart` → verde (23 tests); suite completa verde.

## Phase 3: F3 — Decisión del diálogo en la vista (TDD)

- [x] 3.1 **RED** Nuevo widget test en `test/presentation/screens/convert_screen_test.dart`: override `rssBytes: 1`; tap Procesar → `expect(find.byType(AlertDialog), findsOneWidget)` con el texto de advertencia; tap "Procesar de todos modos" → el lote corre (procesador.llamadas > 0). Run → fails (no hay `advertenciaMemoria` aún).
- [x] 3.2 **GREEN** Añadir `AdvertenciaMemoria` + `HomeEstado.advertenciaMemoria` (+ copyWith) y `rssProcesoProvider` en `providers.dart`.
- [x] 3.3 **GREEN** Reemplazar `_verificarMemoria` (que hoy muestra el diálogo) por cálculo puro `_requiereAdvertenciaMemoria` que setea `advertenciaMemoria` y retorna; `procesar()` orquesta y, si hay advertencia con `context` vivo, guarda `_lotePendiente` y retorna sin ejecutar el lote (queda `ejecutando: true`).
- [x] 3.4 **GREEN** Añadir `reanudarProcesamiento(t, {context})` (re-ejecuta `_ejecutarLote` con `_lotePendiente`, limpia advertencia) y `cancelarAdvertencia(t)` (limpia, `ejecutando: false`, snackbar cancelado). Envolver el try/catch actual en `_ejecutarLote`.
- [x] 3.5 **GREEN** `ConvertBody` en `convert_screen.dart`: `ref.listen(homeControllerProvider.select((s) => s.advertenciaMemoria), ...)` que muestra `showMemoryWarningDialog` (import desde `core/widgets/`) y, según la respuesta, llama `reanudarProcesamiento` o `cancelarAdvertencia`. El controller ya no importa el diálogo.
- [x] 3.6 Verificación: widget test nuevo verde; `home_controller_test.dart` (sin context) verde SIN cambios de asserts (solo override de `rssProcesoProvider`); suite completa verde; grep `showMemoryWarningDialog` en `lib/features/convert` = solo `convert_screen.dart` (la vista).

## Phase 4: Verify + Archive

- [x] 4.1 `flutter test` completo → suite verde (`+413 ~4: All tests passed!`).
- [x] 4.2 Grep de símbolos movidos/eliminados = 0 en `lib/features/audio_manager` y `lib/features/convert` (excepto docs históricos).
- [x] 4.3 Mover `openspec/changes/split-home-controller/` → `openspec/changes/archive/2026-09-05-split-home-controller/` (patrón archive: sin spec promovido, refactor puro).
- [x] 4.4 Commit `chore(sdd): archive split-home-controller change`.

## Work-Unit Commits

1. `refactor(core): move memory warning dialog to core/widgets` — tasks 1.1-1.5 (972e476).
2. `refactor(convert): extract batch loop into _procesarLote` — tasks 2.1-2.2 (3513542).
3. `refactor(convert): move memory dialog decision to the view layer` — tasks 3.1-3.6 (3223191).
4. `chore(sdd): archive split-home-controller change` — task 4.3-4.4.
