# Tasks: Centralizar-shared (P1 — relocación mecánica pura)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~60-80 (21 import edits + 2 file moves + 3 dir deletes) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (3 movidas, una por bloque) |
| Delivery strategy | single-pr |
| Chain strategy | pending |

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | M1 MotorTts contract → shared | PR 1 | git mv + 11 import edits (6 lib + 5 test) |
| 2 | M2 AudioPendiente entity → shared | PR 1 | git mv lib + test + 6 import edits |
| 3 | M3 estimar_memoria use cases → shared | PR 1 | git mv 2 lib + test + 3 import edits |

Cada unidad de trabajo es un commit independiente (work-unit-commits), con `flutter analyze` +
`flutter test` verdes tras cada uno. Relocación pura → sin fase spec (no hay capacidad funcional
nueva que especificar).

## Phase 1: M1 — MotorTts contract

- [x] 1.1 `git mv` `lib/features/convert/domain/contracts/motor_tts.dart` →
  `lib/shared/domain/contracts/`. Impl `MotorTtsSupertonic` se queda en convert/data.
- [x] 1.2 Editar imports de motor_tts (6 lib: run_benchmark, sintetizar_muestra,
  procesar_archivo, convert/data/repositories/motor_tts, voice_preview_service, providers;
  5 test: fakes, providers_test, procesar_archivo_integration_test, benchmark_controller_test,
  run_benchmark_test). `package:.../features/convert/domain/contracts/motor_tts.dart` →
  `shared/domain/contracts/motor_tts.dart`.
- [x] 1.3 `dart format` + `flutter analyze` + `flutter test` (cuenta IGUAL).

## Phase 2: M2 — AudioPendiente entity

- [x] 2.1 `git mv` `lib/features/audio_manager/domain/entities/audio_pendiente.dart` →
  `lib/shared/domain/entities/`.
- [x] 2.2 `git mv` `test/features/audio_manager/domain/entities/audio_pendiente_test.dart` →
  `test/shared/domain/entities/` + edit import interno.
- [x] 2.3 Editar imports de audio_pendiente (4 lib: app_router, audio_manager_screen,
  audio_manager_controller, home_controller; test: audio_manager_screen_test, estimar_memoria_test
  — este último se arregla aquí, no en M3, para mantener el build verde entre commits).
- [x] 2.4 `dart format` + `flutter analyze` + `flutter test` (cuenta IGUAL).

## Phase 3: M3 — estimar_memoria use cases

- [x] 3.1 `git mv` `lib/features/audio_manager/domain/use_cases/estimar_memoria.dart` +
  `estimar_memoria_disponible.dart` → `lib/shared/domain/use_cases/`.
- [x] 3.2 `git mv` `test/features/audio_manager/domain/use_cases/estimar_memoria_test.dart` →
  `test/shared/domain/use_cases/` + edit imports internos.
- [x] 3.3 Editar imports: fixup interno L1 en estimar_memoria_disponible.dart (feature path →
  shared), import en estimar_memoria_test (moved), home_controller (disponible).
- [x] 3.4 Borrar dirs origen ahora vacíos si corresponde (git no trackea dirs vacíos).
- [x] 3.5 `dart format` + `flutter analyze` + `flutter test` (cuenta IGUAL: 406 / 4).

## Phase 4: Verificación

- [x] 4.1 Grep de paths viejos en lib/+test/ = 0 coincidencias (excluye openspec/*.md, docs).
- [x] 4.2 Confirmar lib/features/**/domain/** sin imports cross-feature (0).
- [x] 4.3 ArquiMan Code Review: APROBADO. Pureza shared/domain (sin features, sin dart:io).

## Notas / Excepciones

- `estimar_memoria_disponible.dart` NO tiene test dedicado — YAGNI explicitado (relocación pura,
  sin cambio de lógica).
- 406/4 baseline real (diseño inicial decía 390/4, pero el proyecto creció con benchmark/device-spec
  tests; el baseline verificado al aplicar fue 406/4).
