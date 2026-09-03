# Tasks: device-spec

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~225 (10 files) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Full device-spec change (entity + persistence + UI + tests) | PR 1 | ~225 lines, single cohesive change, all layers travel together |

## Phase 1: Entity (foundation)

- [x] 1.1 RED: Create `test/features/benchmark/domain/entities/device_spec_test.dart` with toMap/fromMap roundtrip test and all-fields-null test
- [x] 1.2 GREEN: Create `lib/features/benchmark/domain/entities/device_spec.dart` — pure `DeviceSpec` class: 5 nullable fields (brand, model, board, hardware, ramBytes), `toMap()`/`fromMap()` factory. No Flutter imports.

## Phase 2: Dependency + composition root

- [x] 2.1 RED: Add `device_info_plus` to `pubspec.yaml` dependencies, run `flutter pub get`
- [x] 2.2 GREEN: Add `deviceSpecProvider = Provider<DeviceSpec?>` to `lib/presentation/controllers/providers.dart` (throw UnimplementedError pattern)
- [x] 2.3 GREEN: Wire device_info read + RAM read in `lib/main.dart` — async block before `runApp`, Platform branching, try-catch fallback to null, `deviceSpecProvider.overrideWithValue(deviceSpec)` in overrides list. Private `_readAndroidRam()` helper.

## Phase 3: Persistence (dual serialization path)

- [x] 3.1 RED: Add roundtrip test with non-null DeviceSpec to `test/features/benchmark/domain/entities/benchmark_result_test.dart`. Add backward-compat test (map without `device_spec` key → null).
- [x] 3.2 GREEN: Add `DeviceSpec? deviceSpec` field to `BenchmarkResult` constructor. Update `toMap()` with `'device_spec': deviceSpec?.toMap()`. Update `fromMap()` to read `device_spec` key (default null).
- [x] 3.3 RED: Add controller persistence test to `test/features/benchmark/presentation/controllers/benchmark_controller_test.dart` — override `deviceSpecProvider` with known value, run `ejecutarFila`, assert `device_spec` key in `preferencias.datos['benchmark_results']`.
- [x] 3.4 GREEN: In `benchmark_controller.dart` `_persistirResultados()`, read `ref.read(deviceSpecProvider)`, add `'device_spec': deviceSpec?.toMap()` to the inline map after `'fecha'`.

## Phase 4: UI + l10n

- [x] 4.1 GREEN: Add l10n keys to `lib/presentation/l10n/app_en.arb` and `app_es.arb`: `benchmark_device_brand`, `benchmark_device_cpu`, `benchmark_device_ram`. Run `flutter gen-l10n`.
- [x] 4.2 GREEN: Add `_DeviceSpecCard` (private `ConsumerWidget`) + `_formatRam()` helper to `lib/features/benchmark/presentation/screens/benchmark_screen.dart`. Insert before info Card in `_BenchmarkBody`. Hidden when null or all-null (brand+model null).
- [x] 4.3 RED: Add widget tests to `test/features/benchmark/presentation/screens/benchmark_screen_test.dart` — card visible with full info, card visible iOS (processor row hidden), card hidden when provider null, card hidden on all-null DeviceSpec.

## Phase 5: Verify

- [x] 5.1 Run `flutter test` — all green across entity, controller, widget layers
- [x] 5.2 Verify no imports from domain/ to data/ or presentation/ (ArquiMan Rule 1)
- [x] 5.3 Verify `BenchmarkResult.fromMap` backward compat with pre-change persisted data (no `device_spec` key)
