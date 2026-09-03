# Proposal: device-spec

## Intent

The Benchmark screen shows conversion speed results but no context about *which device* produced them. This change captures device hardware info (brand, model, CPU board/hardware, RAM) at app startup, persists a canonical `DeviceSpec` alongside each `BenchmarkResult` (backward-compatible with old data), and displays it on the Benchmark screen. Display + persistence only.

## Scope

### In Scope
- `DeviceSpec` pure entity in the benchmark domain (5 nullable fields: brand, model, board, hardware, ramBytes) with `toMap()`/`fromMap()`.
- `device_info_plus` dependency; async device-info read once at composition root (main.dart) before `runApp`.
- `Provider<DeviceSpec?>` at composition root with `overrideWithValue` test seam.
- Persist `device_spec` via BOTH serialization paths: `BenchmarkResult.toMap()`/`fromMap()` AND `BenchmarkController._persistirResultados()` inline map.
- `_DeviceSpecCard` widget at the top of the Benchmark screen (before the info card) with human-readable RAM.
- l10n keys (`benchmark_device_brand`, `benchmark_device_cpu`, `benchmark_device_ram`) in both ARB files.

### Out of Scope
- NO export/import of device data (future change).
- NO backend or Supabase integration.
- NO CPU commercial-name database lookup.
- NO shared-domain move (entity stays in benchmark domain; YAGNI until a second consumer appears).
- NO migration of old persisted data (fromMap defaults null, zero-effort backward compat).

## Capabilities

### New Capabilities
- `deteccion-hardware`: device hardware info captured at startup, persisted with each benchmark result, and displayed on the Benchmark screen.

### Modified Capabilities
- None.

## Approach

- Read device info once in `main.dart`: `device_info_plus` for brand/model, board/hardware (Android only), `/proc/meminfo` (Android) or `ProcessInfo.physicalMemory` (iOS/macOS) for RAM; wrap in try/catch → null fallback.
- Inject via `deviceSpecProvider.overrideWithValue(deviceSpec)` into `ProviderScope`.
- `BenchmarkResult.toMap()` adds `'device_spec'`; `fromMap()` reads it (defaults null).
- `_persistirResultados()` reads `ref.read(deviceSpecProvider)` and adds `device_spec` to the inline map.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modified | Add `device_info_plus` dependency |
| `lib/features/benchmark/domain/entities/device_spec.dart` | New | `DeviceSpec` entity with `toMap`/`fromMap` |
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | Modified | `deviceSpec` nullable field, `toMap()`/`fromMap()` |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Modified | `_persistirResultados()` adds `device_spec` key |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Modified | `_DeviceSpecCard` before info card |
| `lib/presentation/controllers/providers.dart` | Modified | `deviceSpecProvider` |
| `lib/main.dart` | Modified | Async device-info read + inject |
| `lib/presentation/l10n/app_en.arb` / `app_es.arb` | Modified | 3 device card labels |
| Test files (4) | Modified/New | entity, controller, widget tests |
| `openspec/specs/deteccion-hardware/spec.md` | New | functional delta (from sdd-spec) |

## Risks

| Risk | Mitigation |
|------|------------|
| `device_info_plus` throws on all platforms | try/catch → null provider, card hidden |
| `/proc/meminfo` read fails | `_readAndroidRam()` catch → ramBytes null, RAM row hidden |
| iOS board/hardware unavailable | null fields, processor row hidden when both null |
| All-null DeviceSpec (total failure) | Card hidden when brand AND model both null |
| Old persisted data without `device_spec` | fromMap defaults null, no migration needed |

## Rollback Plan

Revert additive changes: remove `DeviceSpec`, `deviceSpecProvider`, `_DeviceSpecCard`, l10n keys, device_info_plus dependency. `benchmark_results` untouched except added `device_spec` key on new entries (old data unaffected).

## Dependencies

- External: `device_info_plus` (device hardware info).
- Internal: `Provider` from `providers.dart`, `BenchmarkResult` entity, `_persistirResultados()`.

## Success Criteria

- [ ] `DeviceSpec` roundtrip via `toMap`/`fromMap` (unit test).
- [ ] `device_spec` persisted via both serialization paths (controller + entity tests).
- [ ] `_DeviceSpecCard` visible with device data, hidden when null/all-null (widget tests).
- [ ] `flutter analyze` clean; `flutter test` green (strict TDD).

## Estimate

~225 changed lines, ~10 files, risk Low → single PR (no chaining).
