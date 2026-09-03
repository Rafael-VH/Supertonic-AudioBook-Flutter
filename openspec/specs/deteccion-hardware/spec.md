# Detección de Hardware Specification

## Purpose

The Benchmark screen shows conversion speed results but no context about *which device* produced them. This capability collects device hardware info (brand, model, CPU board/hardware, RAM) at app startup, persists a canonical `DeviceSpec` alongside each `BenchmarkResult` (backward-compatible with old data), and displays it on the Benchmark screen via a `_DeviceSpecCard`. Display + persistence only — no export, no backend, no CPU-name table.

## Requirements

### Requirement: Device info capture at startup (DSC-1) — Prioridad: must

At composition root, before `runApp`, the system SHALL read device hardware (brand, model, board, hardware, ramBytes) exactly once and expose it as `DeviceSpec?` via a `Provider<DeviceSpec?>`. Brand and model SHALL come from `device_info_plus`. Board and hardware SHALL come from `device_info_plus` on Android and be null on iOS/macOS. RAM SHALL come from `/proc/meminfo` (Android) or `ProcessInfo.physicalMemory` (iOS/macOS), fallback null.

#### Scenario: Successful capture on Android

- GIVEN the app starts on an Android device
- WHEN `main.dart` reads device info before `runApp`
- THEN `deviceSpecProvider` yields a `DeviceSpec` with non-null brand, model, board, hardware, and ramBytes

#### Scenario: Successful capture on iOS (board/hardware null)

- GIVEN the app starts on an iOS device
- WHEN `main.dart` reads device info before `runApp`
- THEN `deviceSpecProvider` yields a `DeviceSpec` with non-null brand, model, ramBytes
- AND `board` and `hardware` are null

#### Scenario: device_info_plus total failure → null provider

- GIVEN `device_info_plus` throws on all platforms
- WHEN `main.dart` catches the exception
- THEN `deviceSpecProvider` yields null (not an all-null `DeviceSpec`)

#### Scenario: RAM read failure → ramBytes null but brand/model present

- GIVEN `device_info_plus` succeeds but `/proc/meminfo` read fails
- WHEN `main.dart` constructs the `DeviceSpec`
- THEN `ramBytes` is null
- AND `brand`, `model`, `board`, `hardware` are populated normally

### Requirement: BenchmarkResult persists deviceSpec — toMap/fromMap (DSC-2) — Prioridad: must

`BenchmarkResult.toMap()` SHALL include a `device_spec` key with `deviceSpec?.toMap()`. `BenchmarkResult.fromMap()` SHALL read the `device_spec` key and construct via `DeviceSpec.fromMap()`, defaulting to null when the key is absent.

#### Scenario: Roundtrip with non-null DeviceSpec

- GIVEN a `BenchmarkResult` with a non-null `DeviceSpec` (brand=Pixel, model=8, board=cheetah, hardware=cheetah, ramBytes=8GB)
- WHEN `toMap()` is called then `fromMap()` on the result
- THEN all 5 `DeviceSpec` fields survive the roundtrip

#### Scenario: Old data without deviceSpec → null

- GIVEN a persisted map with no `device_spec` key (pre-change data)
- WHEN `BenchmarkResult.fromMap()` deserializes it
- THEN `deviceSpec` is null
- AND all other fields deserialize normally

### Requirement: BenchmarkController persists deviceSpec — inline map (DSC-3) — Prioridad: must

`BenchmarkController._persistirResultados()` SHALL read `deviceSpecProvider` and add a `device_spec` key (via `DeviceSpec.toMap()`) to the inline persistence map, after the `fecha` key.

#### Scenario: Controller persistence includes deviceSpec

- GIVEN a known `DeviceSpec` injected via provider override
- WHEN `ejecutarFila()` completes and `_persistirResultados()` runs
- THEN `preferencias.datos['benchmark_results'][-1]['device_spec']` equals `deviceSpec.toMap()`

### Requirement: _DeviceSpecCard visibility (DSC-4) — Prioridad: must

The Benchmark screen SHALL display a `_DeviceSpecCard` at the top (before the info card) when `deviceSpecProvider` yields a non-null `DeviceSpec` with at least one non-null field (brand or model). The card SHALL be completely hidden when `deviceSpec` is null or when both `brand` and `model` are null.

#### Scenario: Card visible with full device info

- GIVEN `deviceSpecProvider` yields a `DeviceSpec` with brand, model, board, hardware, ramBytes
- WHEN the Benchmark screen renders
- THEN `_DeviceSpecCard` is visible
- AND brand/model row, processor row, and RAM row are all displayed

#### Scenario: Card visible on iOS — processor row hidden

- GIVEN `deviceSpecProvider` yields a `DeviceSpec` with brand, model, ramBytes but board=null, hardware=null
- WHEN the Benchmark screen renders
- THEN brand/model row and RAM row are visible
- AND the processor row is not rendered

#### Scenario: Card hidden when provider yields null

- GIVEN `deviceSpecProvider` yields null
- WHEN the Benchmark screen renders
- THEN no device card elements are found in the widget tree

#### Scenario: Card hidden on total device_info failure (all null)

- GIVEN `deviceSpecProvider` yields a `DeviceSpec` with brand=null, model=null, board=null, hardware=null, ramBytes=null
- WHEN the Benchmark screen renders
- THEN no device card elements are found in the widget tree

### Requirement: RAM human-readable formatting (DSC-5) — Prioridad: must

The `_DeviceSpecCard` SHALL display RAM as a human-readable string: `X.X GB` when >= 1 GB, `X MB` otherwise. When `ramBytes` is null, the RAM row SHALL NOT be rendered.

#### Scenario: 8 GB RAM display

- GIVEN `ramBytes` = 8,589,934,592
- WHEN the card renders the RAM row
- THEN it displays "8.0 GB"

#### Scenario: null RAM → row hidden

- GIVEN `ramBytes` is null
- WHEN the card renders
- THEN the RAM row is not present

### Requirement: Test seam — provider override (DSC-6) — Prioridad: must

Tests SHALL override `deviceSpecProvider` via `overrideWithValue` to inject known `DeviceSpec` values (or null). No reader class or abstract interface is needed.

#### Scenario: Widget test with faked deviceSpec

- GIVEN a widget test that overrides `deviceSpecProvider` with a test `DeviceSpec`
- WHEN `BenchmarkScreen` is pumped
- THEN the widget tree contains the expected device info text

#### Scenario: Controller test with faked deviceSpec

- GIVEN a controller test that overrides `deviceSpecProvider` with a known value
- WHEN `ejecutarFila()` runs
- THEN the persisted data contains the correct `device_spec` sub-map

## NON-Requirements

- NO export/import of device data (future change)
- NO backend or Supabase integration
- NO CPU commercial-name database lookup
- NO shared-domain move (entity stays in benchmark domain; YAGNI until a second consumer appears)
- NO migration of old persisted data (fromMap defaults null, zero-effort backward compat)
