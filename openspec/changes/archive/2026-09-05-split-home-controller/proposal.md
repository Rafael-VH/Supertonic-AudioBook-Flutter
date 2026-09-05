# Proposal: split-home-controller

## Intent

`home_controller.dart` (779 lines) sigue siendo un god class y cruza a la UI de
otro feature: `features/convert/presentation/controllers/home_controller.dart:15`
importa `features/audio_manager/presentation/screens/memory_warning_dialog.dart`
y el controller llama `showMemoryWarningDialog` (`:620`) desde un "ViewModel"
(hallazgos A1/A2 de la auditoría 2026-09-05). El diálogo es 100% genérico (solo
usa `flutter/material` + l10n) y está mal ubicado; además, la decisión de mostrarlo
pertenece a la vista (patrón MVVM del proyecto: la vista mapea estado → UI).

Mantener comportamiento IDENTICAL (18+ tests de `home_controller_test.dart` +
widget tests de `convert_screen_test.dart` como red de seguridad). NO reescribir la
feature (ponytail): solo (a) relocar el diálogo a un hogar compartido, (b) extraer
el loop de conversión a un método cohesivo, y (c) mover la decisión de mostrar el
diálogo de memoria del controller a la vista mediante el patrón evento-estado
ya usado con `MensajeSnackbar` (`ref.listen` en la pantalla).

## Scope

### In Scope

- Relocar `memory_warning_dialog.dart` de `features/audio_manager/presentation/screens/`
  a `lib/core/widgets/` (cambio mecánico puro; el único caller en producción es el
  controller y el test del diálogo). Sin cambios de lógica.
- Extraer el loop por archivo de `procesar()` (`:465-552`) a un método privado
  cohesivo `_procesarLote(...)` — Extract Method behavior-preserving (opción (a)
  del plan: no crear un UC `ProcesarLote` ahora; evaluar como follow-up).
- Mover la decisión de mostrar el diálogo a la capa de vista: el controller expone
  un evento/estado (`advertenciaMemoria`) y `ConvertBody` lo escucha con
  `ref.listen` (patrón `MensajeSnackbar` ya existente). El controller deja de
  importar/llamar `showMemoryWarningDialog`.
- Añadir un seam de "bytes disponibles" (`rssProcesoProvider`) para poder probar el
  umbral >0.7 de forma determinista desde un widget test (hoy lee
  `ProcessInfo.currentRss` directo, no testeable).

### Out of Scope

- NO crear un UC de dominio `ProcesarLote` (opción (b)) — parameter bombing y
  acceso a `state`/`ref`; el precedente 2026-09-02 rechazó sobre-extraer.
- NO dividir `HomeController` en múltiples controllers (selección vs
  procesamiento) — rechazado en el precedente 2026-09-02.
- NO tocar A3 (gate modelo), A4 (unificar filesystem contracts), A5 (colapsar tier
  historial) — diferidos en el plan.
- NO cambiar el contrato del UC compartido `run_benchmark`/`debeDetenerse`
  (decisión C2.5 conservadora ya aplicada).
- NO reescribir lógica de `procesar()` ni cambiar TTS / navegación.

## Capabilities

### New Capabilities

None — refactor puro; no se introduce capability externa nueva.

### Modified Capabilities

None — el comportamiento a nivel spec no cambia. La capability `memory-estimation`
(borrador en `audio-manager`, MEM-2) solo restringe contenido/acciones del diálogo,
no su ubicación ni quién lo muestra.

## Approach

1. **F1 — Relocar el diálogo.** `git mv` de `features/audio_manager/presentation/screens/memory_warning_dialog.dart`
   → `lib/core/widgets/memory_warning_dialog.dart` + test → `test/core/widgets/memory_warning_dialog_test.dart`.
   Actualizar el import en `home_controller.dart:15`. Cero lógica.
2. **F2 — Extract Method `_procesarLote`.** Sacar el `for` de `procesar()` a un método
   privado que recibe por parámetro lo que hoy son locales del closure (`seleccion`,
   `inicio`, `salida`, `steps`, `speed`, `formatos`, `lang`, `benchmark`) y devuelve
   los contadores `(exitos, errores, procesados)`; `acumulados`/`historialPendiente`
   se mutan por referencia. Movimiento puro.
3. **F3 — Decisión del diálogo a la vista.** El controller deja de recibir la
   necesidad de `BuildContext` para el diálogo: `_verificarMemoria` se transforma en
   un cálculo puro (`_advertenciaMemoria`) que, si `fraccion > 0.7` y hay vista
   (`context != null && context.mounted`), setea `state.advertenciaMemoria` y pausa;
   `procesar()` delega el lote a `_ejecutarLote(...)` (que envuelve el try actual y
   llama a `_procesarLote`). La vista (`ConvertBody`) escucha `advertenciaMemoria`
   con `ref.listen`, muestra `showMemoryWarningDialog` (importado desde
   `core/widgets/`) y reanuda con `reanudarProcesamiento(t, context:)` o cancela con
   `cancelarPorAdvertenciaMemoria(t)`. Tests de controller (sin `context`) siguen
   verdes y nunca pausan. `rssProcesoProvider` permite overridear el RSS en tests.
4. Verificación y archive SDD (sin spec promovido — refactor puro, precedente
   `refactor-home-controller`).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/core/widgets/memory_warning_dialog.dart` | New (move) | Diálogo genérico relocado desde `features/audio_manager/presentation/screens/` |
| `lib/features/audio_manager/presentation/screens/memory_warning_dialog.dart` | Deleted | Origen del diálogo (se mueve) |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modified | Elimina import del diálogo; extrae `_procesarLote`/`_ejecutarLote`; evento `advertenciaMemoria` |
| `lib/features/convert/presentation/screens/convert_screen.dart` | Modified | `ref.listen(advertenciaMemoria)` + muestra el diálogo (decisión en la vista) |
| `lib/presentation/controllers/providers.dart` | Modified | Nuevo `rssProcesoProvider` (seam para tests del umbral) |
| `test/core/widgets/memory_warning_dialog_test.dart` | New (move) | Test del diálogo relocado |
| `test/presentation/controllers/home_controller_test.dart` | Modified | Si acaso ajustes de wiring; sin cambios de asserts de comportamiento |
| `test/presentation/screens/convert_screen_test.dart` | Modified | Nuevo test: la pantalla muestra el diálogo cuando el controller lo pide (rss override) |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Drift de comportamiento en el extract del loop | Low | Extract Method puro; `_procesarLote` recibe los mismos valores capturados que hoy; correr `home_controller_test.dart` tras cada paso |
| El pause/resume del diálogo altera transiciones de estado | Low | Mantener el gate `context != null && mounted` (los tests de controller sin context nunca pausan); reanudar = mismo `_ejecutarLote` del path directo |
| Relocación rompe imports | Very Low | Único caller en prod es el controller (verificado por grep); el test se mueve con el archivo |

## Rollback Plan

Refactor puro por fases commit-eables. Revert = `git revert` los commits (F1→F3 en
orden inverso); el diálogo vuelve a `audio_manager/presentation/screens/` y el
controller recupera el import. `flutter test` debe pasar antes/después.

## Dependencies

- None new. Reutiliza `EstimarMemoriaDisponible` (`shared/domain/use_cases/`),
  `estimar_memoria.dart`, l10n existente, patrón `MensajeSnackbar` + `ref.listen`.
  Nuevo provider trivial `rssProcesoProvider` en `providers.dart`.

## Success Criteria

- [ ] `home_controller.dart` ya no importa ni llama `showMemoryWarningDialog` (grep = 0 en lib/features/convert)
- [ ] `procesar()` < ~150 líneas (hoy ~207); el loop vive en `_procesarLote`
- [ ] El diálogo vive en `lib/core/widgets/` y su test en `test/core/widgets/`
- [ ] `ConvertBody` muestra el diálogo vía `ref.listen(advertenciaMemoria)` (decisión en la vista)
- [ ] Widget test nuevo: la pantalla muestra el diálogo cuando `fraccion > 0.7` (rss override) y reanuda/cancela según la respuesta
- [ ] `flutter test` pasa — suite completa verde; tests de controller sin cambios de asserts
