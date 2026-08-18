# Proposal: Fix Clean Architecture Critical Violations

## Intent

The arquic review found 6 critical violations of the Clean Architecture Dependency Rule: entity misplaced (shared → features), `dart:io` in domain layer (2 files), `package:logger` in domain layer (2 files), and `dart:io` in a domain contract. These MUST be fixed before any new feature work — they contaminate the domain layer and break the "domain depends on nothing" invariant.

## Scope

### In Scope
- Move `Archivo` entity from `features/convert/` to `shared/domain/entities/`
- Remove `dart:io` from `procesar_archivo.dart` (inject `FileSystem` contract)
- Remove `dart:io` from `modelo_gestor.dart` (return `String` path instead of `Directory`)
- Remove `package:logger` from 2 use cases (inject logging callback)

### Out of Scope
- Refactoring the full `procesar_archivo.dart` use case (only remove `dart:io`)
- Changing `Archivo` entity internals (it's already pure)
- Adding tests for the fixes (separate concern)
- Any non-critical arquic issues

## Approach

**Order from least disruptive to most disruptive:**

1. **C4-C5: Remove Logger** — 2 files, zero structural change, just inject callback
2. **C6: Fix ModeloGestor contract** — 1 file + 1 implementation, return `String`
3. **C1-C2: Move Archivo** — 6 files need import updates, create new location
4. **C3: Remove dart:io from ProcesarArchivo** — most complex, inject `FileSystem`

## Fix Plan

### Fix 1: Remove Logger from Domain Layer (C4-C5)

**What**: Inject a logging callback instead of importing `package:logger` directly.

**Why**: Domain layer must not depend on external packages. Logger is a data/infrastructure concern.

**Files to modify**:
- `lib/features/convert/domain/use_cases/procesar_archivo.dart` — replace `_log` calls with injected callback
- `lib/features/convert/domain/use_cases/sintetizar_muestra.dart` — replace `_log` calls with injected callback

**Approach**: Add optional `void Function(String message, {String level})? onLog` parameter to constructors. Default to no-op. The DI layer (data/) can inject the real logger.

**Verification**: `flutter analyze lib/features/convert/domain/use_cases/` — no `package:logger` imports

---

### Fix 2: Fix ModeloGestor Contract (C6)

**What**: Change `Future<Directory> asegurarModelo()` to `Future<String> asegurarModelo()`.

**Why**: Domain contracts cannot use `dart:io` types. Return path string instead.

**Files to modify**:
- `lib/features/modelo/domain/contracts/modelo_gestor.dart` — change return type
- `lib/features/modelo/data/repositories/modelo_gestor_impl.dart` (or wherever the impl lives) — return `directory.path` instead of `Directory`
- All call sites that use the return value — adapt to `String`

**Verification**: `flutter analyze lib/features/modelo/` — no `dart:io` in domain contracts

---

### Fix 3: Move Archivo Entity to Shared (C1-C2)

**What**: Move `Archivo` from `features/convert/domain/entities/` to `shared/domain/entities/`.

**Why**: `shared/` cannot import from `features/`. `Archivo` is used across features (biblioteca, convert) so it belongs in shared domain.

**Files to modify**:
- **Create**: `lib/shared/domain/entities/archivo.dart` (copy from old location)
- **Delete**: `lib/features/convert/domain/entities/archivo.dart`
- **Update imports** (6 files):
  - `lib/shared/domain/contracts/repositorio_archivos.dart`
  - `lib/shared/data/repositories/repositorio_archivos.dart`
  - `lib/features/convert/domain/use_cases/procesar_archivo.dart`
  - `lib/features/convert/presentation/controllers/home_controller.dart`
  - `lib/features/convert/presentation/screens/movil/contenido_archivos.dart`
  - `lib/features/convert/presentation/widgets/archivo_tile.dart`

**Verification**: `flutter analyze lib/` — no cross-feature imports from shared

---

### Fix 4: Remove dart:io from ProcesarArchivo (C3)

**What**: Extract `dart:io` operations (File, Directory, Platform.pathSeparator) into an injected contract.

**Why**: Domain layer must not depend on `dart:io`. File operations are a data/infrastructure concern.

**Files to modify**:
- **Create**: `lib/features/convert/domain/contracts/file_system.dart` — abstract contract with methods like `createDirectory(String path)`, `createTempFile(String dir, String suffix)`, `deleteFile(String path)`, `renameFile(String from, String to)`, `fileExists(String path)`, `parentOf(String path)`, `pathSeparator`
- **Modify**: `lib/features/convert/domain/use_cases/procesar_archivo.dart` — inject `FileSystem`, replace all `File()`/`Directory()`/`Platform` calls
- **Create**: `lib/features/convert/data/repositories/file_system_local.dart` — implementation using `dart:io`
- **Update**: DI registration to provide the implementation

**Verification**: `flutter analyze lib/features/convert/domain/` — no `dart:io` imports in domain layer

---

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/shared/domain/entities/` | New | `archivo.dart` moves here |
| `lib/features/convert/domain/use_cases/` | Modified | Remove logger, remove dart:io |
| `lib/features/convert/domain/contracts/` | New | `file_system.dart` contract |
| `lib/features/modelo/domain/contracts/` | Modified | Return type change |
| `lib/shared/domain/contracts/` | Modified | Import path update |
| `lib/shared/data/repositories/` | Modified | Import path update |
| 6 presentation files | Modified | Import path updates |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Breaking compilation during move | Low | All 6 import sites identified; run `flutter analyze` after each fix |
| Missing a call site for ModeloGestor | Low | Grep for `Future<Directory>` and `asegurarModelo` |
| FileSystem abstraction adds complexity | Low | Contract is minimal (6-8 methods), matches existing usage |

## Rollback Plan

Each fix is independently revertible:
1. Logger removal: revert the callback injection, restore `_log = Logger()`
2. ModeloGestor: revert return type, restore `Future<Directory>`
3. Archivo move: move file back, revert all 6 imports
4. FileSystem: delete contract + impl, restore direct `dart:io` usage

## Dependencies

- None — all fixes are internal refactors with no external dependency changes

## Success Criteria

- [ ] `flutter analyze lib/features/convert/domain/` shows zero `dart:io` or `package:logger` imports
- [ ] `flutter analyze lib/features/modelo/domain/` shows zero `dart:io` imports
- [ ] `lib/shared/domain/contracts/repositorio_archivos.dart` does NOT import from `features/`
- [ ] `flutter test` passes (no regressions)
- [ ] Arquic review passes with zero critical issues
