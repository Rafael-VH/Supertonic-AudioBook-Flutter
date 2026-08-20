# Delta Spec: Benchmark Motor TTS

> **Change**: `benchmark-motor`  
> **Domain**: `benchmark` (new feature module)  
> **Status**: Draft  
> **Derived from**: `proposal.md`

---

## 1. Module Structure

A self-contained feature module at `lib/features/benchmark/` following Clean Architecture. The module depends ONLY on domain-layer contracts (`MotorTts`, `VoiceConfig`, `RepositorioPreferencias`), never on `data/` or `presentation/` of other features.

### 1.1 New Files

| Path | Layer | Purpose |
|------|-------|---------|
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | Domain | Result entity with serialization |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | Domain | Core benchmark logic (pure) |
| `lib/features/benchmark/domain/use_cases/estimar_tiempo.dart` | Domain | Estimation from benchmark data |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | Presentation | Riverpod Notifier for benchmark state |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | Presentation | UI: progress, results table, re-run |
| `test/features/benchmark/domain/use_cases/run_benchmark_test.dart` | Test | Unit test with fake MotorTts |
| `test/features/benchmark/domain/use_cases/estimar_tiempo_test.dart` | Test | Unit test for estimation logic |

### 1.2 Modified Files

| Path | Change |
|------|--------|
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | Return `ProcesarResultado` instead of `ResultadoProceso`; add `ProcesarResultado` class |
| `lib/features/convert/presentation/controllers/home_controller.dart` | Read `ProcesarResultado` fields; store per-file metrics; display estimated time |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add benchmark `_SeccionCard` before "Acerca de" |
| `lib/presentation/routing/app_router.dart` | Add `Rutas.benchmark` constant + `/benchmark` route |
| `lib/presentation/controllers/providers.dart` | Add `benchmarkControllerProvider` |
| `lib/presentation/l10n/app_es.arb` | Add benchmark + estimation i18n strings |
| `lib/presentation/l10n/app_en.arb` | Add benchmark + estimation i18n strings |

---

## 2. Domain Entities

### 2.1 `BenchmarkResult`

```dart
class BenchmarkResult {
  const BenchmarkResult({
    required this.tamanios,
    required this.voiceConfig,
    required this.fecha,
  });

  /// char count → processing time in milliseconds
  final Map<int, int> tamanios;
  final VoiceConfig voiceConfig;
  final DateTime fecha;
}
```

**Serialization** (for persistence in `RepositorioPreferencias` JSON):

```dart
Map<String, Object?> toMap() => {
  'tamanios': {for (final e in tamanios.entries) '${e.key}': e.value},
  'voice_config': { /* voiceConfig fields */ },
  'fecha': fecha.toIso8601String(),
};

factory BenchmarkResult.fromMap(Map<String, Object?> map) => BenchmarkResult(
  tamanios: {for (final e in (map['tamanios'] as Map).entries) int.parse(e.key as String): e.value as int},
  voiceConfig: VoiceConfig(/* from map['voice_config'] */),
  fecha: DateTime.parse(map['fecha'] as String),
);
```

### 2.2 `ProcesarResultado`

Wraps the existing `ResultadoProceso` with per-file metrics:

```dart
class ProcesarResultado {
  const ProcesarResultado({
    required this.estado,
    required this.segmentos,
    required this.duracionAudioSeg,
  });

  final ResultadoProceso estado;
  final int segmentos;
  final double duracionAudioSeg;
}
```

---

## 3. Benchmark Scenarios

### 3.1 Text Sizes

The benchmark SHALL test 6 text sizes: **1500, 3000, 5000, 7500, 10000, 15000** characters.

Text source: a const Lorem ipsum string (sufficient length) truncated to each target size. No external library required.

### 3.2 Per-Size Measurement

For each text size, the benchmark SHALL:

1. Generate Lorem ipsum text truncated to `N` characters.
2. Segment the text using the existing `segmentarTexto()` function.
3. Synthesize each segment via `MotorTts.sintetizar()` with the user's current `VoiceConfig` (voz, steps, speed, langVoz).
4. Measure **wall-clock time** from first `sintetizar()` call to last, inclusive.
5. Discard generated audio (no files written to disk).
6. Record the total wall-clock time in milliseconds.

### 3.3 Acceptance Scenarios

**Scenario: Successful benchmark run**

```
Given the TTS model is downloaded and loaded
  And the user has voice config: voz="default", steps=32, speed=1.0, langVoz="es"
When the user taps "Run benchmark"
Then the benchmark SHALL synthesize text at each of the 6 sizes in order
  And progress SHALL update after each size completes (paso 1/6, 2/6, ... 6/6)
  And a BenchmarkResult SHALL be returned with 6 entries in `tamanios`
  And each entry's key SHALL be one of {1500, 3000, 5000, 7500, 10000, 15000}
  And each entry's value SHALL be > 0 (positive milliseconds)
  And the result SHALL be persisted to `benchmark_results` in preferences JSON
```

**Scenario: Benchmark cancellation**

```
Given the benchmark is running (e.g., at size 5000)
When the user taps "Cancel"
Then synthesis SHALL stop after the current segment completes
  And partial results for completed sizes SHALL be discarded (no partial persistence)
  And the screen SHALL return to the idle state with a "Cancelled" message
```

**Scenario: Model not downloaded**

```
Given the TTS model is NOT downloaded
When the user navigates to `/benchmark`
Then the screen SHALL redirect to `/modelo` (model download screen)
```

**Scenario: Voice config mismatch**

```
Given a benchmark result exists for voz="default" with steps=32
  And the user changes voice config to steps=64
When the user views the benchmark screen
Then the screen SHALL display the existing result but mark it as "Estimate based on previous voice config"
  And re-running SHALL overwrite the result with the new voice config
```

---

## 4. Per-File Metrics

### 4.1 What to Track

During normal processing (`ProcesarArchivo.procesar()`), each file SHALL produce:

| Metric | Type | Source |
|--------|------|--------|
| `segmentos` | `int` | Count of segments from `segmentarTexto()` |
| `duracionAudioSeg` | `double` | Sum of audio durations for all exported formats (seconds), computed from the existing `_exportador.duracionAudio()` call |

### 4.2 Change to `ProcesarArchivo`

The return type of `procesar()` SHALL change from `Future<ResultadoProceso>` to `Future<ProcesarResultado>`. The `ProcesarResultado` wraps the original `ResultadoProceso` (as `estado`) with the two new fields.

**Acceptance Scenarios:**

```
Given a file with 12 segments that processes successfully
When `procesar()` completes
Then the returned ProcesarResultado SHALL have estado=ResultadoProceso.ok, segmentos=12, duracionAudioSeg > 0.0
```

```
Given a file that is empty after cleaning
When `procesar()` completes
Then the returned ProcesarResultado SHALL have estado=ResultadoProceso.omitido, segmentos=0, duracionAudioSeg=0.0
```

```
Given a file that cannot be read
When `procesar()` completes
Then the returned ProcesarResultado SHALL have estado=ResultadoProceso.error, segmentos=0, duracionAudioSeg=0.0
```

### 4.3 `HomeController` Consumption

`HomeController.procesar()` SHALL read the `ProcesarResultado` fields:

- Log segment count and audio duration per file.
- Accumulate total segments and total audio duration across all processed files.
- After all files processed, store the aggregate (totalChars, totalTime, totalSegments) in an in-memory field for estimation display.

---

## 5. Estimation Logic

### 5.1 `EstimarTiempo` Use Case

A pure function (no side effects) that computes estimated processing time:

```dart
/// Estimates processing time for a given text length based on benchmark data.
///
/// Returns estimated seconds, or null if no benchmark data exists.
double? estimarTiempo({
  required BenchmarkResult benchmark,
  required int textoChars,
})
```

**Algorithm:**

1. If `benchmark.tamanios` is empty, return `null`.
2. Compute `avgMsPerChar` = weighted average of `(time_ms / char_count)` across all benchmark entries.
3. Return `textoChars * avgMsPerChar / 1000.0` (in seconds).

The estimation is a **simple linear interpolation** from the benchmark average. It is approximate by design — marked as such in the UI.

### 5.2 Acceptance Scenarios

```
Given a benchmark with {1500: 2300, 3000: 4500, 5000: 7800, 7500: 11500, 10000: 15200, 15000: 22800}
When estimating for a file with 6000 chars
Then the result SHALL be approximately (6000 × avgMsPerChar / 1000) seconds
  And the result SHALL be > 0
```

```
Given no benchmark results exist
When estimating for any file
Then the result SHALL be null
```

### 5.3 Display in `HomeController`

- When files are selected and benchmark data exists, `HomeController` SHALL compute the estimated time for the total character count of selected files.
- The estimate SHALL be displayed in the status area (below the file list, above the process button) as: `"Tiempo estimado: ~{X} min {Y}s"` (localized).
- If no benchmark exists, the estimate line SHALL NOT be shown.
- The estimate SHALL be recalculated when the file selection changes.

---

## 6. UI Specifications

### 6.1 Benchmark Screen (`/benchmark`)

**Layout (top to bottom):**

1. **AppBar**: Title = "Benchmark Motor" (localized).
2. **Status card**: Shows last benchmark date and average chars/sec (or "No benchmark data" if none exists).
3. **Run button**: `FilledButton` — "Ejecutar benchmark" (localized). Disabled while running. Tapping starts the benchmark.
4. **Progress indicator** (visible only while running):
   - `LinearProgressIndicator` (indeterminate → determinate at 1/6, 2/6, etc.).
   - Text below: `"Probando tamaño {N} chars ({paso}/6)"`.
5. **Cancel button** (visible only while running): Text button — "Cancelar".
6. **Results table** (visible after completion):
   - Header row: `Tamaño` | `Tiempo` | `Chars/seg`
   - 6 data rows, one per size, sorted ascending by char count.
   - Each row: `{N} chars` | `{X}s` | `{Y} chars/s`.
7. **Last run footer**: "Última corrida: {fecha formateada}".

### 6.2 Settings Integration

A new `_SeccionCard` SHALL be added to `SettingsBody` **before** the "Acerca de" card:

```dart
_SectionCard(
  titulo: t.benchmark_titulo,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t.benchmark_resumen(lastRunFormatted, avgCharsPerSec)),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
        onPressed: () => context.push(Rutas.benchmark),
        icon: const Icon(Icons.speed),
        label: Text(t.benchmark_abrir),
      ),
    ],
  ),
)
```

If no benchmark data exists: show `"Sin datos — ejecutá el benchmark para estimar tiempos."` instead of the summary.

### 6.3 Acceptance Scenarios

```
Given the user is on the Settings screen
When the benchmark card is visible
Then it SHALL show before the "Acerca de" card
  And it SHALL display last run date (or "Sin datos" if no benchmark)
  And tapping the button SHALL navigate to `/benchmark`
```

```
Given the benchmark is running
When viewing the benchmark screen
Then the Run button SHALL be disabled
  And a LinearProgressIndicator SHALL be visible
  And the current size and step (e.g., "Probando tamaño 5000 chars (3/6)") SHALL be shown
  And a Cancel button SHALL be visible
```

```
Given the benchmark has completed
When viewing the benchmark screen
Then a table with 6 rows SHALL be displayed
  And each row SHALL show size, time, and chars/sec
  And the last run date SHALL be shown below the table
```

---

## 7. Error Handling

### 7.1 Model Not Downloaded

**Behavior:** The `BenchmarkScreen` SHALL check `modeloControllerProvider.listo` on mount. If `false`, SHALL navigate to `/modelo` via `context.go(Rutas.modelo)`.

### 7.2 Cancellation

**Behavior:** The `BenchmarkController` SHALL expose a `cancelar()` method. The `RunBenchmark` use case SHALL accept a `bool Function() debeDetenerse` callback (same pattern as `ProcesarArchivo`). When cancelled mid-run:
- No partial result is persisted.
- The controller returns to idle state with a "Cancelado" status.

### 7.3 Memory Pressure

**Behavior:** The benchmark reuses `segmentarTexto()` to chunk text. Audio fragments from `sintetizar()` are NOT accumulated — each segment's audio is measured and discarded immediately. The only memory cost is the segment text buffer (≤1500 chars) and a single `Float32List` from `sintetizar()` at a time.

### 7.4 TTS Synthesis Failure

```
Given the benchmark is running
When MotorTts.sintetizar() throws for a segment
Then that size's timing SHALL be recorded as the time spent before the failure
  And the benchmark SHALL continue to the next size
  And the error SHALL be logged
```

### 7.8 Acceptance Scenarios

```
Given the TTS model is not downloaded
When navigating to `/benchmark`
Then the user SHALL be redirected to `/modelo`
```

```
Given the benchmark is running
When MotorTts.sintetizar() throws on size 5000
Then sizes 1500 and 3000 results SHALL be retained
  And size 5000 SHALL show the partial time (or "Error" in the table)
  And the benchmark SHALL continue to sizes 7500, 10000, 15000
```

---

## 8. Persistence

### 8.1 Storage Location

Benchmark results are stored in the existing preferences JSON file under the key `"benchmark_results"`. The existing `RepositorioPreferencias.cargar()` / `guardar()` methods are used directly — no new repository or data layer needed.

### 8.2 JSON Format

```json
{
  "benchmark_results": {
    "tamanios": {
      "1500": 2300,
      "3000": 4500,
      "5000": 7800,
      "7500": 11500,
      "10000": 15200,
      "15000": 22800
    },
    "voice_config": {
      "voz": "default",
      "steps": 32,
      "speed": 1.0,
      "langVoz": "es"
    },
    "fecha": "2026-08-19T12:00:00.000"
  }
}
```

### 8.3 Acceptance Scenarios

```
Given a benchmark completes successfully
When the result is persisted
Then the preferences JSON SHALL contain a "benchmark_results" key
  And the key SHALL contain tamanios, voice_config, and fecha fields
  And tamanios SHALL have exactly 6 entries with int keys and int values
```

```
Given a previous benchmark result exists
When a new benchmark completes
Then the old "benchmark_results" value SHALL be overwritten (not appended)
```

```
Given the preferences file does not exist or is corrupted
When loading benchmark results
Then the code SHALL treat it as "no benchmark data" (empty result)
```

---

## 9. i18n

### 9.1 New Strings for `app_es.arb`

```json
{
  "benchmark_titulo": "Benchmark Motor",
  "benchmark_abrir": "Abrir benchmark",
  "benchmark_resumen": "Última corrida: {fecha} — {velocidad}",
  "@benchmark_resumen": {
    "placeholders": {
      "fecha": {"type": "String"},
      "velocidad": {"type": "String"}
    }
  },
  "benchmark_sin_datos": "Sin datos — ejecutá el benchmark para estimar tiempos.",
  "benchmark_btn_ejecutar": "Ejecutar benchmark",
  "benchmark_btn_cancelar": "Cancelar",
  "benchmark_progreso": "Probando tamaño {tamanio} chars ({paso}/6)",
  "@benchmark_progreso": {
    "placeholders": {
      "tamanio": {"type": "String"},
      "paso": {"type": "String"}
    }
  },
  "benchmark_cancelado": "Benchmark cancelado.",
  "benchmark_tabla_tamanio": "Tamaño",
  "benchmark_tabla_tiempo": "Tiempo",
  "benchmark_tabla_velocidad": "Chars/seg",
  "benchmark_ultima_corrida": "Última corrida: {fecha}",
  "@benchmark_ultima_corrida": {
    "placeholders": {
      "fecha": {"type": "String"}
    }
  },
  "estimacion_tiempo": "Tiempo estimado: ~{tiempo}",
  "@estimacion_tiempo": {
    "placeholders": {
      "tiempo": {"type": "String"}
    }
  },
  "estimacion_requiere_benchmark": "Ejecutá el benchmark para ver estimaciones."
}
```

### 9.2 New Strings for `app_en.arb`

```json
{
  "benchmark_titulo": "Benchmark Motor",
  "benchmark_abrir": "Open benchmark",
  "benchmark_resumen": "Last run: {fecha} — {velocidad}",
  "@benchmark_resumen": {
    "placeholders": {
      "fecha": {"type": "String"},
      "velocidad": {"type": "String"}
    }
  },
  "benchmark_sin_datos": "No data — run the benchmark to estimate processing times.",
  "benchmark_btn_ejecutar": "Run benchmark",
  "benchmark_btn_cancelar": "Cancel",
  "benchmark_progreso": "Testing size {tamanio} chars ({paso}/6)",
  "@benchmark_progreso": {
    "placeholders": {
      "tamanio": {"type": "String"},
      "paso": {"type": "String"}
    }
  },
  "benchmark_cancelado": "Benchmark cancelled.",
  "benchmark_tabla_tamanio": "Size",
  "benchmark_tabla_tiempo": "Time",
  "benchmark_tabla_velocidad": "Chars/sec",
  "benchmark_ultima_corrida": "Last run: {fecha}",
  "@benchmark_ultima_corrida": {
    "placeholders": {
      "fecha": {"type": "String"}
    }
  },
  "estimacion_tiempo": "Estimated time: ~{tiempo}",
  "@estimacion_tiempo": {
    "placeholders": {
      "tiempo": {"type": "String"}
    }
  },
  "estimacion_requiere_benchmark": "Run the benchmark to see estimates."
}
```

---

## 10. Routing

### 10.1 New Route

Add `static const benchmark = '/benchmark';` to `Rutas` class.

Add a new `GoRoute` in `appRouterProvider`:

```dart
GoRoute(
  path: Rutas.benchmark,
  builder: (_, __) => const BenchmarkScreen(),
),
```

The `/benchmark` route SHALL NOT require the model gate (user must have the model downloaded to run the benchmark, but the screen itself handles this check and redirects if needed).

---

## 11. Providers

### 11.1 `benchmarkControllerProvider`

```dart
final benchmarkControllerProvider =
    NotifierProvider<BenchmarkController, BenchmarkEstado>(
  BenchmarkController.new,
);
```

The `BenchmarkController` (a Riverpod `Notifier`) SHALL:

- Read `repositorioPreferenciasProvider` for loading/saving benchmark results.
- Read `motorTtsProvider` for the TTS engine.
- Read `settingsControllerProvider` (or equivalent) for the current `VoiceConfig`.
- Expose `ejecutar()` (run benchmark) and `cancelar()` methods.
- Expose `estado` with states: `idle`, `ejecutando(progreso)`, `resultado(BenchmarkResult)`, `error(String)`.

---

## 12. Integration Points

### 12.1 Benchmark → Estimation

The `EstimarTiempo` use case bridges benchmark data to processing estimation:

1. `HomeController` reads `benchmark_results` from preferences on init.
2. When files are selected, it sums their character counts.
3. It calls `estimarTiempo(benchmark, totalChars)` to get estimated seconds.
4. It displays the estimate in the status area (or hides if null).

### 12.2 Per-File Metrics → Estimation Refinement (Future)

The per-file metrics (segment count + audio duration) collected during normal processing are logged and available for future refinement of the estimation model. For this change, they are **logged only** — not used to update the estimation algorithm. This keeps the estimation model stable and predictable.

---

## 13. Out of Scope

- Telemetry / device info upload
- Cloud-based benchmark comparison
- Benchmark charts/graphs (table only)
- Automatic re-benchmarking on voice change
- Per-file metrics feeding back into estimation (logged only in this change)
