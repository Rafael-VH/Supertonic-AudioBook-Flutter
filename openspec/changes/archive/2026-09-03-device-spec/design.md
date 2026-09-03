# Design: device-spec

## Technical Approach

Add a `DeviceSpec` pure entity in the benchmark domain, wire it through a nullable Provider at the composition root, persist it alongside `BenchmarkResult` via both serialization paths (`toMap()` and `_persistirResultados()` inline map), and display it in a new `_DeviceSpecCard` widget on the benchmark screen. Device info read happens once at startup in `main.dart`; all downstream code receives it via the provider override.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| Entity location | `benchmark/domain/entities/device_spec.dart` | `shared/domain/entities/` | Only benchmark uses it now; YAGNI — move to shared if a second consumer appears |
| Entity serialization | `toMap()`/`fromMap()` on entity | Pure entity + separate model | Existing `BenchmarkResult` already has `toMap()`/`fromMap()` on the entity — follow existing pattern |
| Provider type | `Provider<DeviceSpec?>` | StateProvider, Reader class | Nullable Provider with `overrideWithValue` is the simplest test seam. No state mutations needed. No reader class (YAGNI). |
| RAM reading | `dart:io` in composition root | Abstract contract in domain | Platform-specific I/O belongs in composition root (presentation may use `dart:io`). Domain stays pure. |
| `_DeviceSpecCard` | Private `ConsumerWidget` | Separate file | Small widget, tightly coupled to benchmark screen only. One file is simpler. |
| Labels l10n | Add to existing ARB files | Hardcoded strings | Project uses `generate: true` with `app_en.arb`/`app_es.arb`. Follow existing convention. |

## DeviceSpec Entity Shape

```dart
// lib/features/benchmark/domain/entities/device_spec.dart
class DeviceSpec {
  const DeviceSpec({
    this.brand,
    this.model,
    this.board,
    this.hardware,
    this.ramBytes,
  });

  final String? brand;
  final String? model;
  final String? board;    // Android: from device_info board; iOS: null
  final String? hardware; // Android: from device_info hardware; iOS: null
  final int? ramBytes;

  Map<String, Object?> toMap() => {
    'brand': brand,
    'model': model,
    'board': board,
    'hardware': hardware,
    'ramBytes': ramBytes,
  };

  factory DeviceSpec.fromMap(Map<String, Object?> map) => DeviceSpec(
    brand: map['brand'] as String?,
    model: map['model'] as String?,
    board: map['board'] as String?,
    hardware: map['hardware'] as String?,
    ramBytes: (map['ramBytes'] as num?)?.toInt(),
  );
}
```

## Data Flow

```
main.dart (async startup)
  ├─ device_info_plus → DeviceAndroidInfo / DeviceIosInfo
  ├─ /proc/meminfo or ProcessInfo.physicalMemory → ramBytes
  ├─ new DeviceSpec(brand, model, board, hardware, ramBytes)
  └─ deviceSpecProvider.overrideWithValue(deviceSpec)
       │
       ├─ benchmark_screen.dart → _DeviceSpecCard (reads provider, displays)
       └─ benchmark_controller.dart → _persistirResultados() (reads provider, persists inline)
                                         └─ BenchmarkResult.toMap() also serializes deviceSpec
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modify | Add `device_info_plus` dependency |
| `lib/features/benchmark/domain/entities/device_spec.dart` | Create | `DeviceSpec` entity with 5 nullable fields, `toMap`/`fromMap` |
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | Modify | Add `deviceSpec` nullable field, update `toMap()` and `fromMap()` |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Modify | `_persistirResultados()` reads provider, adds `device_spec` key to inline map |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Modify | Add `_DeviceSpecCard` private widget, insert before info Card |
| `lib/presentation/controllers/providers.dart` | Modify | Add `deviceSpecProvider = Provider<DeviceSpec?>` |
| `lib/main.dart` | Modify | Async device-info read + inject into overrides |
| `lib/presentation/l10n/app_en.arb` | Modify | Add device card labels (3 strings) |
| `lib/presentation/l10n/app_es.arb` | Modify | Add device card labels (3 strings) |
| `test/features/benchmark/domain/entities/device_spec_test.dart` | Create | Roundtrip `toMap`/`fromMap` test |
| `test/features/benchmark/domain/entities/benchmark_result_test.dart` | Modify | Add roundtrip tests for `deviceSpec` in `toMap`/`fromMap` |
| `test/features/benchmark/presentation/controllers/benchmark_controller_test.dart` | Modify | Override `deviceSpecProvider` in test containers; add persistence test for inline map |
| `test/features/benchmark/presentation/screens/benchmark_screen_test.dart` | Modify | Override `deviceSpecProvider`; test card visibility |

## Serialization: Dual-Path Correctness (CRITICAL)

**Problem**: `BenchmarkResult.toMap()` and `BenchmarkController._persistirResultados()` both build persistence maps independently.

**Solution**:
1. `BenchmarkResult.toMap()` adds `'device_spec': deviceSpec?.toMap()` after existing keys
2. `BenchmarkResult.fromMap()` adds `deviceSpec: map['device_spec'] != null ? DeviceSpec.fromMap(...) : null`
3. `_persistirResultados()` reads `ref.read(deviceSpecProvider)` and adds `'device_spec': deviceSpec?.toMap()` to the inline map
4. Roundtrip test in `benchmark_result_test.dart`
5. Persistence test in `benchmark_controller_test.dart`

**Invariant**: Both serialization paths call `DeviceSpec.toMap()`. A single method change updates both. The roundtrip test catches drift.

## Composition Root Wiring (main.dart)

Existing pattern: async `main()` → `WidgetsFlutterBinding.ensureInitialized()` → async directory reads → `runApp(ProviderScope(overrides: [...]))`. Read device info once before `runApp`, Platform-branching (Android vs iOS/macOS), try-catch fallback to null, `deviceSpecProvider.overrideWithValue(deviceSpec)` in overrides.

## Provider Seam (providers.dart)

```dart
/// Device hardware info, read once at startup. Null on failure.
final deviceSpecProvider = Provider<DeviceSpec?>(
  (_) => throw UnimplementedError('deviceSpecProvider se inyecta en main.dart'),
);
```

**Test seam**: `deviceSpecProvider.overrideWithValue(myFakeDeviceSpec)` or `.overrideWithValue(null)`. No reader class needed.

## _DeviceSpecCard Widget

Inserted BEFORE the info `Card` in `_BenchmarkBody.build()`. Reads `ref.watch(deviceSpecProvider)`, hidden when null or when brand+model both null. Card shows up to 3 rows (brand/model, processor, RAM); processor row hidden when board+hardware both null; RAM row hidden when ramBytes null.

**Human-readable RAM**: `gb >= 1.0 ? '${gb.toStringAsFixed(1)} GB' : '${(bytes / (1024*1024)).toInt()} MB'`.

## l10n Strings

| Key | English | Spanish |
|-----|---------|---------|
| `benchmark_device_brand` | `Device` | `Dispositivo` |
| `benchmark_device_cpu` | `Processor` | `Procesador` |
| `benchmark_device_ram` | `RAM` | `RAM` |

Brand/model values are NOT localized (proper nouns from the OS). Only labels.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `DeviceSpec.toMap()`/`fromMap()` roundtrip | device_spec_test.dart — pure, no mocks |
| Unit | `BenchmarkResult` with `DeviceSpec` roundtrip | Extend benchmark_result_test.dart |
| Unit | Old data backward-compat | fromMap(no device_spec key) → null |
| Controller | `_persistirResultados()` includes `device_spec` | Override provider, run `ejecutarFila`, inspect persisted map |
| Widget | `_DeviceSpecCard` renders when non-null | Override provider, pump, find Text widgets |
| Widget | `_DeviceSpecCard` hidden when null | Override provider null, `findsNothing` |

## Edge Cases

1. **iOS null fields**: board/hardware always null on iOS. Card hides Processor row.
2. **Old persisted data**: fromMap defaults null when key absent. No migration.
3. **RAM read failure**: `_readAndroidRam()` catches, returns null. RAM row hidden.
4. **device_info_plus failure / all-null**: card hidden when brand+model both null.
5. **Concurrent runs**: provider read-only after startup. No races.

## Migration / Rollout

No migration required. `deviceSpec` defaults to null in `fromMap()`, so old data loads correctly. Purely additive.

## Open Questions

None. All design decisions are resolved.
