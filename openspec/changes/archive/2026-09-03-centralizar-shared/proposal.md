# Proposal: Centralizar-shared (P1 — eliminar imports cross-feature en domain)

## Intent

Eliminar todos los imports cross-feature en la capa **domain** moviendo los 3 bloques
compartidos puros a `lib/shared/domain/`. Tras este cambio, la única dependencia de dominio
entre features (benchmark → convert/MotorTts) desaparece y **ningún archivo de domain
importa otra feature**.

> ⚠️ **Relocación mecánica pura**: NO introduce ninguna capacidad funcional nueva.
> El comportamiento queda EXACTAMENTE igual (verificado: 406 tests idénticos, prueba de
> blob-hash byte-idéntico). Por ello NO se promueve ninguna capability spec a
> `openspec/specs/` — el archivo de este cambio documenta la relocación, no una capacidad.

## Scope

### In Scope
- **M1 MotorTts contract** → `shared/domain/contracts/motor_tts.dart`. Implementación
  `MotorTtsSupertonic` queda en `convert/data/repositories/`.
- **M2 AudioPendiente entity** → `shared/domain/entities/audio_pendiente.dart`.
- **M3 estimar_memoria + estimar_memoria_disponible** → `shared/domain/use_cases/`.
- Actualizar TODOS los imports + mover los tests que acompañan al código movido.
- Verificar (analyze) que no queda ningún import cross-feature en `lib/features/**/domain/`.

### Out of Scope
- Refactor de `home_controller.dart` (cross-feature de benchmark entities/presentation → es
  cambio P2 aparte).
- Cualquier cambio de lógica o comportamiento. **Relocación mecánica pura**.
- No tocar `convert/data/repositories/motor_tts.dart` salvo su import del contrato.

## Approach

1. Mover cada archivo (git mv) + crear carpeta destino en `shared/domain/{contracts,entities,use_cases}`.
2. Actualizar imports: `features/...` → `shared/...` por cada path.
3. Mover tests: `audio_pendiente_test.dart` → `test/shared/domain/entities/`;
   `estimar_memoria_test.dart` → `test/shared/domain/use_cases/`.
4. `dart format` + `flutter analyze` + `flutter test` (cuenta de tests debe quedar IGUAL).

## Import Edits VERIFICADOS (grep real, no estimado)

**M1 (11 sitios: 6 lib + 5 test)** — lib: run_benchmark.dart, providers.dart,
voice_preview_service.dart, convert/data/repositories/motor_tts.dart, sintetizar_muestra.dart,
procesar_archivo.dart — test: fakes.dart, providers_test.dart,
procesar_archivo_integration_test.dart, benchmark_controller_test.dart, run_benchmark_test.dart

**M2 (7 sitios: 4 lib + 3 test)** — lib: app_router.dart, audio_manager_screen.dart,
audio_manager_controller.dart, home_controller.dart — test: audio_manager_screen_test.dart,
estimar_memoria_test.dart, audio_pendiente_test.dart (move)

**M3 (3 sitios: 2 lib + 1 test)** — lib: home_controller.dart (disponible),
estimar_memoria_disponible.dart (interno, ambos mudan) — test: estimar_memoria_test.dart (move)

> ⚠️ Nota: el estimado inicial del orchestrator (M1≈4, M2≈3, M3≈2) estaba **subestimado**.
> Real: **21 edits de import** (11 lib + 8 test + 2 movimientos de test). home_controller y
> estimar_memoria_test se cuentan en 2 movidas.

## Pureza (ArquiMan) — VERIFICADO
- `motor_tts.dart`: solo `dart:typed_data` + `shared/domain/constants/producto.dart`. PURO.
- `audio_pendiente.dart`: solo `equatable`. PURO.
- `estimar_memoria.dart`: sin imports. PURO.
- `estimar_memoria_disponible.dart`: solo `estimar_memoria.dart` (mismo dir tras mover). PURO.
- Ninguno usa `dart:io` ni flutter → califican para `shared/domain`. `shared/domain` NO
  importa features.

## Capabilities (espec)

- **New**: None (refactor puro, sin capacidad nueva).
- **Modified**: None (sin cambio de comportamiento a nivel spec). `memory-estimation` y
  `audio-pending-management` specs en `openspec/changes/audio-manager` describen uso
  cross-feature ya cubierto; solo cambia la ubicación física, no el contrato.
- **Promoted to `openspec/specs/`**: **NONE** — este cambio es una relocación
  comportamiento-preservante sin capacidad funcional nueva (documentado explícitamente).

## Success Criteria

- [ ] `flutter analyze` limpio (zero cross-feature imports en domain, zero dart:io en shared/domain).
- [ ] `flutter test` pasa con la MISMA cuenta de tests (406 passed / 4 skipped, baseline real).
- [ ] No queda ningún `features/<A>/domain` importando `features/<B>` (verify con grep).
- [ ] ArquiMan Plan+Code Review: APROBADO.

## Risks

| Risk | Prob. | Mitigación |
|------|-------|-----------|
| Path roto por import no actualizado | Low | grep completo previo + `flutter analyze` + `flutter test` |
| Cambio de comportamiento accidental | Low | Relocación pura; **cuenta de tests sin cambio** como guard |
| `dart:io` se cuele en shared | Low | `flutter analyze` verifica pureza; pieces ya son puros |

## Rollback

`git revert` del commit (relocación pura, sin migración de datos). Cada movimiento es
independientemente reversible.
