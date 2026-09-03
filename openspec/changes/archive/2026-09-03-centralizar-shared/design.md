# Design: Centralizar-shared (P1 — relocación mecánica pura)

## Technical Approach

Mover 3 bloques puros de domain de features → `lib/shared/domain/`, actualizando imports y
moviendo tests. SIN cambios de lógica. `git mv` + edit de imports. Verificado con grep real
(codebase, no estimación).

Relocación comportamiento-preservante: sin capacidad funcional nueva → **no se genera ni
promueve ninguna capability spec**.

## Target structure (ya existente en shared/ → solo agregar)

- `lib/shared/domain/contracts/motor_tts.dart` (M1) [contracts/ ya existe]
- `lib/shared/domain/entities/audio_pendiente.dart` (M2) [entities/ ya existe]
- `lib/shared/domain/use_cases/estimar_memoria.dart` + `estimar_memoria_disponible.dart` (M3)
  [use_cases/ ya existe]
- Tests: `test/shared/domain/entities/audio_pendiente_test.dart`,
  `test/shared/domain/use_cases/estimar_memoria_test.dart`

## Critical finding — imports internos de los archivos movidos (VERIFICADO leyendo cada uno)

TODOS usan `package:` imports, NO `../` relativos → NO hay quebradero de ruta relativa.
El ÚNICO fixup interno es:
- `estimar_memoria_disponible.dart` L1: `package:.../features/audio_manager/domain/use_cases/estimar_memoria.dart`
  → `package:.../shared/domain/use_cases/estimar_memoria.dart`.
- `motor_tts.dart`: ya importa `shared/domain/constants/producto.dart` por path completo → NO cambia.
- `audio_pendiente.dart`: solo `equatable` → sin cambio.
- `estimar_memoria.dart`: sin imports → sin cambio.

## Import-update matrix (grep-verificado)

OLD package prefix `.../features/{feat}/domain/...` → NEW `.../shared/domain/...`; resto del
path igual.

M1 `features/convert/domain/contracts/motor_tts.dart` → `shared/domain/contracts/motor_tts.dart`:
lib: run_benchmark.dart, sintetizar_muestra.dart, procesar_archivo.dart,
convert/data/repositories/motor_tts.dart (impl se queda), voice_preview_service.dart,
presentation/controllers/providers.dart.
test: support/fakes.dart, presentation/controllers/providers_test.dart,
features/convert/domain/use_cases/procesar_archivo_integration_test.dart,
features/benchmark/presentation/controllers/benchmark_controller_test.dart,
features/benchmark/domain/use_cases/run_benchmark_test.dart.
(lib/main.dart importa la IMPLEMENTACIÓN convert/data/repositories/motor_tts.dart → NO tocar)

M2 `features/audio_manager/domain/entities/audio_pendiente.dart` → `shared/domain/entities/audio_pendiente.dart`:
lib: presentation/routing/app_router.dart, audio_manager/presentation/screens/audio_manager_screen.dart,
audio_manager/presentation/controllers/audio_manager_controller.dart,
convert/presentation/controllers/home_controller.dart.
test: presentation/screens/audio_manager_screen_test.dart (solo edit),
use_cases/estimar_memoria_test.dart (MUEVE + 2 edits), entities/audio_pendiente_test.dart
(MUEVE + edit).

M3 `features/audio_manager/domain/use_cases/estimar_memoria*.dart` → `shared/domain/use_cases/`:
lib: use_cases/estimar_memoria_disponible.dart (MUEVE + fixup interno a estimar_memoria),
convert/presentation/controllers/home_controller.dart (importa disponible).
test: use_cases/estimar_memoria_test.dart (MUEVE; también importa audio_pendiente → 2 edits).

CONFIRMADO (no estimado): 11 lib (M1=6,M2=4,M3=1) + 8 test unique (M1=5,M2/M3 share
estimar_memoria_test). home_controller se cuenta en M2 y M3. estimar_memoria_test en M2 y M3.

## Test relocation

Mueven físicamente (git mv → test/shared/...):
- test/features/audio_manager/domain/entities/audio_pendiente_test.dart → test/shared/domain/entities/
- test/features/audio_manager/domain/use_cases/estimar_memoria_test.dart → test/shared/domain/use_cases/
(ambos `git mv` para preservar historia; luego edit import path interno.
`estimar_memoria_disponible` NO tiene test — YAGNI documentado en archive.)
Solo edit de import (no mueven): audio_manager_screen_test.dart y todos los de M1.

## Orden sugerido de ejecución

1. git mv archivos lib (M1,M2,M3) + crear dirs destino (shared/domain/use_cases ya existe;
   contracts/entities ya existen).
2. Editar imports en todos los sitios de la matriz (lib primero, luego test).
3. git mv los 2 tests + editar sus imports internos.
4. Borrar dirs ahora vacíos si quedan (verificar con glob que no queden archivos; git no
   trackea dirs vacíos).
5. dart format + flutter analyze + flutter test.

## Verification plan (comportamiento idéntico)

- `flutter test`: cuenta IGUAL (406 passed / 4 skipped) — guard principal de no-regresión.
- `flutter analyze`: 0 issues nuevos (5 pre-existentes ajenos).
- Grep final de paths viejos: NINGUNA coincidencia en lib/ o test/ con
  `features/convert/domain/contracts/motor_tts`, `features/audio_manager/domain/entities/audio_pendiente`,
  `features/audio_manager/domain/use_cases/estimar_memoria` (los openspec/*.md históricos sí los
  mencionan — EXCLUIR de la búsqueda, son docs).
- Confirmar que lib/features/**/domain/** NO importa features/<otra> (cross-feature = 0).
- Prueba de blob-hash: motor_tts, audio_pendiente, estimar_memoria byte-idénticos
  (OLD blob == NEW blob); estimar_memoria_disponible solo difiere en L1 (fixup de import).

## ArquiMan review (PLAN)

✅ APROBADO. Dirección de dependencia correcta: shared no importa features (verificado:
motor_tts→producto es shared→shared; estimar_memoria_disponible→estimar_memoria será
shared→shared tras fixup). Domain puro: ningún moved file usa dart:io ni flutter.
⚠️ No dejar código huérfano: la implementación MotorTtsSupertonic (features/convert/data)
sigue viva e importa el nuevo contrato.

## Refactoryman review (PLAN)

Smell diagnosticado: Shotgun Surgery / cross-feature coupling en domain (benchmark→convert,
convert→audio_manager). Técnica: MOVE (move field/class entre modules) — la más pequeña que
resuelve. Comportamiento observable PRESERVADO (relocación pura, cero lógica cambiada).
STOP después del move — nada de cleanup adicional (el home_controller cross-feature a benchmark
entities es P2 aparte, fuera de scope).

## Rollback

git revert del commit (relocación pura). Cada move independientemente reversible.
