# Design: conversion-history

## Technical Approach

Extend the existing benchmark infrastructure with a persistent conversion history and configurable benchmark sizes. The approach follows established patterns: entity with `toMap()`/`fromMap()` following `BenchmarkResult`, prefs persistence via `RepositorioPreferencias`, and Riverpod state management.

## Architecture Decisions

### Decision: ConversionEntry location

**Choice**: `lib/features/benchmark/domain/entities/conversion_entry.dart`
**Alternatives considered**: Placing in `convert` domain (where `ProcesarResultado` lives)
**Rationale**: The entity is consumed and displayed by BenchmarkScreen. Keeping it in `benchmark/domain/entities/` next to `BenchmarkResult` follows the existing entity pattern and avoids cross-feature imports. The benchmark feature is the read/display side of this data.

### Decision: Prefs key format

**Choice**: Store history as JSON array under key `conversion_history` in `RepositorioPreferencias`
**Alternatives considered**: SQLite, separate file, in-memory only
**Rationale**: Prefs is already used for benchmark results and settings. JSON array is the simplest persistence that survives app restarts. 100-entry cap limits size to ~10KB. No migration needed — missing key returns empty list.

### Decision: ProcesarResultado.caracteres as required field

**Choice**: Add `caracteres` as a required named parameter to `ProcesarResultado`
**Alternatives considered**: Optional field with default 0
**Rationale**: The caller always knows the character count (it's `textoPlano.length` after cleaning). Making it required ensures every call site provides it, preventing silent data loss. The field is always available in `procesar()`.

### Decision: Lorem ipsum extension

**Choice**: Increase `_loremBase` repetitions from 200 to cover 30000 chars
**Alternatives considered**: Generate lorem programmatically
**Rationale**: `_loremBase` is ~450 chars × 200 = ~90,000 chars already sufficient. The real change is adding the 11 size values to `_tamaniosPrueba`. The `_lorem` final already covers 15000; extending to 30000 means adding more repetitions if needed (current 200×450=90K already covers it).

## Data Flow

```
HomeController.procesar() 
  → ProcesarArchivo.procesar() returns ProcesarResultado(caracteres: textoPlano.length, ...)
  → HomeController writes ConversionEntry to prefs (key: conversion_history)
  
BenchmarkController.build()
  → loads conversion_history from prefs → BenchmarkEstado.historial

BenchmarkScreen
  → watches benchmarkControllerProvider → renders history DataTable
  → FilterChip bottom sheet → BenchmarkEstado.tamaniosSeleccionados
  → RunBenchmark.ejecutar(tamanios: selected) → BenchmarkResult
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/benchmark/domain/entities/conversion_entry.dart` | Create | `ConversionEntry` entity with `toMap()`/`fromMap()`, fields: nombreArchivo, caracteres, segmentos, duracionAudioSeg, fecha |
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Modify | Add `caracteres` (required int) to `ProcesarResultado`; set `textoPlano.length` in all return sites |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | Modify | Add `tamanios` param to `ejecutar()` with default `[1500, 3000, 6000, 9000, 12000, 15000]`; extend `_tamaniosPrueba` to 11 sizes |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Modify | Add `tamaniosDisponibles`, `tamaniosSeleccionados`, `historial` to `BenchmarkEstado`; load history in `build()` |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Modify | Add size selection bottom sheet, history DataTable, dynamic progress denominator |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Modify | After `ResultadoProceso.ok`, persist `ConversionEntry` to prefs |
| `lib/presentation/l10n/app_es.arb` | Modify | New strings: benchmark sizes, history table headers, duration format |
| `lib/presentation/l10n/app_en.arb` | Modify | English equivalents |

## Interfaces / Contracts

### ConversionEntry

```dart
class ConversionEntry {
  const ConversionEntry({
    required this.nombreArchivo,
    required this.caracteres,
    required this.segmentos,
    required this.duracionAudioSeg,
    required this.fecha,
  });

  final String nombreArchivo;
  final int caracteres;
  final int segmentos;
  final double duracionAudioSeg;
  final DateTime fecha;

  Map<String, Object?> toMap() => {
    'nombreArchivo': nombreArchivo,
    'caracteres': caracteres,
    'segmentos': segmentos,
    'duracionAudioSeg': duracionAudioSeg,
    'fecha': fecha.toIso8601String(),
  };

  factory ConversionEntry.fromMap(Map<String, Object?> map) {
    return ConversionEntry(
      nombreArchivo: map['nombreArchivo'] as String? ?? '',
      caracteres: (map['caracteres'] as num?)?.toInt() ?? 0,
      segmentos: (map['segmentos'] as num?)?.toInt() ?? 0,
      duracionAudioSeg: (map['duracionAudioSeg'] as num?)?.toDouble() ?? 0,
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
```

### ProcesarResultado change

```dart
class ProcesarResultado {
  const ProcesarResultado({
    required this.estado,
    required this.segmentos,
    required this.duracionAudioSeg,
    required this.caracteres, // NEW
  });
  // ... existing fields ...
  final int caracteres; // NEW
}
```

### RunBenchmark.ejecutar() signature change

```dart
Future<BenchmarkResult> ejecutar({
  required VoiceConfig voiceConfig,
  required void Function(int paso, int total, int tamanio) onProgreso,
  bool Function()? debeDetenerse,
  List<int>? tamanios, // NEW — null uses default
}) async {
  final sizes = tamanios ?? [1500, 3000, 6000, 9000, 12000, 15000];
  // ... rest uses `sizes` instead of `_tamaniosPrueba`
}
```

### BenchmarkEstado additions

```dart
class BenchmarkEstado {
  const BenchmarkEstado({
    // ... existing fields ...
    this.tamaniosDisponibles = const [1500, 3000, 6000, 9000, 12000, 15000, 18000, 21000, 24000, 27000, 30000],
    this.tamaniosSeleccionados = const [1500, 3000, 6000, 9000, 12000, 15000],
    this.historial = const [],
  });

  final List<int> tamaniosDisponibles;
  final List<int> tamaniosSeleccionados;
  final List<ConversionEntry> historial;
  // ... copyWith adds these params ...
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `ConversionEntry.toMap()`/`fromMap()` roundtrip | Serialize then deserialize, assert equality |
| Unit | History cap at 100 entries | Append 101 entries, assert oldest pruned |
| Unit | `RunBenchmark.ejecutar()` respects `tamanios` param | Mock MotorTts, pass custom sizes, verify only those sizes processed |
| Unit | `ProcesarResultado.caracteres` populated | Verify `procesar()` returns correct char count |
| Unit | `BenchmarkEstado.copyWith()` preserves new fields | Assert defaults and overrides work |

## Migration / Rollout

No migration required. New prefs key `conversion_history` starts empty. Existing `benchmark_results` key unchanged. `ProcesarResultado.caracteres` is additive — no consumer depends on it yet.

## Open Questions

- [ ] Should history entries include voice config used? (Not in proposal — omit for now)
- [ ] Should the history table be scrollable inside a fixed-height container or in the main ListView? (Prefer: wrap in SizedBox with fixed height to avoid competing with benchmark controls)
