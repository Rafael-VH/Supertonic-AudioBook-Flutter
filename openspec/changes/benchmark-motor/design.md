# Design: Benchmark Motor TTS

## Technical Approach

Módulo aislado en `lib/features/benchmark/` con Clean Architecture (domain + presentation, sin data layer propio). `RunBenchmark` es un caso de uso puro que recibe `MotorTts`, `VoiceConfig` y un callback de cancelación, usa `segmentarTexto()` existente, y sintetiza sin escribir archivos a disco. `EstimarTiempo` es una función pura que computa ms/char promedio del benchmark y lo aplica linealmente. `BenchmarkController` (Riverpod Notifier) orquesta el ciclo de vida: idle → ejecutando → resultado/error. Persistencia via `RepositorioPreferencias.cargar()`/`guardar()` con la key `benchmark_results` — sin nuevo repositorio.

## Architecture Decisions

| # | Decision | Alternatives | Rationale |
|---|----------|--------------|-----------|
| D1 | Módulo en `lib/features/benchmark/` con domain + presentation | Archivos sueltos en `lib/domain/` | El proyecto ya tiene `lib/features/{module}/` (convert, settings, modelo, editor_metadata). Seguir el patrón existente. |
| D2 | `RunBenchmark` recibe `MotorTts` como contrato de dominio, no lo instancia | Importar provider en domain | Clean Architecture: domain no depende de Riverpod ni de `data/`. El controller inyecta el motor. |
| D3 | `RunBenchmark` acepta `bool Function() debeDetenerse` | `CancelableOperation` o `CancellationToken` | Patrón ya establecido en `ProcesarArchivo.procesar()` (line 94). Consistencia. |
| D4 | Sin data layer propio — persistencia via `RepositorioPreferencias` directamente | Nuevo `BenchmarkRepository` | `RepositorioPreferencias.cargar()`/`guardar()` ya soportan任意 keys en el JSON. Un wrapper sería YAGNI. |
| D5 | `BenchmarkController` como `Notifier<BenchmarkEstado>` (no `StateNotifier`) | `StateNotifier` | Todos los controllers del proyecto usan `Notifier<T>` (`HomeController`, `BibliotecaController`). Consistencia. |
| D6 | Texto Lorem como `const` en el módulo, truncado a cada tamaño | Generador aleatorio, archivo externo | Determinismo: mismo texto cada vez = resultados comparables. Sin dependencias externas. |
| D7 | `ProcesarResultado` wrapping `ResultadoProceso` | Modificar `ResultadoProceso` directamente | No romper el enum existente. El wrapper agrega campos sin cambiar callers existentes que usan el enum. |
| D8 | Estimacion lineal simple (avg ms/char) | Regresion polinomial, spline | YAGNI: la relacion texto-largo/TTS es suficientemente lineal para una app de usuario. Marcar como "aproximado" en UI. |

## Data Models

### BenchmarkResult

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

  Map<String, Object?> toMap() => {
    'tamanios': {for (final e in tamanios.entries) '${e.key}': e.value},
    'voice_config': {
      'voz': voiceConfig.voz,
      'steps': voiceConfig.steps,
      'speed': voiceConfig.speed,
      'langVoz': voiceConfig.langVoz,
    },
    'fecha': fecha.toIso8601String(),
  };

  factory BenchmarkResult.fromMap(Map<String, Object?> map) {
    final raw = map['tamanios'] as Map? ?? {};
    return BenchmarkResult(
      tamanios: {
        for (final e in raw.entries) int.parse(e.key as String): e.value as int,
      },
      voiceConfig: VoiceConfig(
        voz: ((map['voice_config'] as Map?)?['voz'] as String?) ?? 'default',
        steps: (((map['voice_config'] as Map?)?['steps'] as num?)?.toInt()) ?? 32,
        speed: (((map['voice_config'] as Map?)?['speed'] as num?)?.toDouble()) ?? 1.0,
        langVoz: ((map['voice_config'] as Map?)?['langVoz'] as String?) ?? 'es',
      ),
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  bool get vozCoincide => true; // Checked externally by comparing with current VoiceConfig

  double get avgMsPerChar {
    if (tamanios.isEmpty) return 0;
    var total = 0.0;
    for (final e in tamanios.entries) {
      total += e.value / e.key;
    }
    return total / tamanios.length;
  }

  double get avgCharsPerSec {
    final ms = avgMsPerChar;
    return ms > 0 ? 1000.0 / ms : 0;
  }
}
```

### ProcesarResultado

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

### BenchmarkEstado (controller state)

```dart
class BenchmarkEstado {
  const BenchmarkEstado({
    this.ejecutando = false,
    this.pasoActual = 0,
    this.tamanioActual = 0,
    this.resultado,
    this.cancelado = false,
    this.error,
  });

  final bool ejecutando;
  final int pasoActual;        // 1..6
  final int tamanioActual;     // chars being tested
  final BenchmarkResult? resultado;
  final bool cancelado;
  final String? error;

  BenchmarkEstado copyWith({...});
}
```

## Use Case Interfaces

### RunBenchmark

```dart
class RunBenchmark {
  RunBenchmark({required MotorTts motor, required DomainLogger logger});

  /// Executes the benchmark at 6 text sizes using [motor] with [voiceConfig].
  ///
  /// Calls [onProgreso] after each size completes (paso 1/6 .. 6/6).
  /// Checks [debeDetenerse] before each size; if true, returns partial results
  /// (completed sizes only — no persistence).
  Future<BenchmarkResult> ejecutar({
    required VoiceConfig voiceConfig,
    required void Function(int paso, int total, int tamanio) onProgreso,
    bool Function()? debeDetenerse,
  }) async { ... }
}
```

**Implementation outline:**
1. Define `const tamanios = [1500, 3000, 5000, 7500, 10000, 15000]`
2. Define a const Lorem ipsum string (≥15000 chars)
3. For each size N in `tamanios`:
   a. Check `debeDetenerse()` — if true, break
   b. `texto = lorem.substring(0, N)`
   c. `await motor.cambiarVoz(voiceConfig.voz)`
   d. `segmentos = segmentarTexto(texto)`
   e. `stopwatch = Stopwatch()..start()`
   f. For each segment: `await motor.sintetizar(segment, steps: voiceConfig.steps, speed: voiceConfig.speed, lang: voiceConfig.langVoz)` — discard result
   g. `stopwatch.stop()`
   h. `resultados[N] = stopwatch.elapsedMilliseconds`
   i. `onProgreso(paso, 6, N)`
4. Return `BenchmarkResult(tamanios: resultados, voiceConfig: voiceConfig, fecha: DateTime.now())`

### EstimarTiempo

```dart
/// Estimates processing time in seconds for [textoChars] characters.
/// Returns null if [benchmark] has no data.
double? estimarTiempo({
  required BenchmarkResult benchmark,
  required int textoChars,
}) {
  if (benchmark.tamanios.isEmpty) return null;
  return textoChars * benchmark.avgMsPerChar / 1000.0;
}
```

## Controller Interface

```dart
class BenchmarkController extends Notifier<BenchmarkEstado> {
  @override
  BenchmarkEstado build() {
    _cargarResultado();
    return const BenchmarkEstado();
  }

  void _cargarResultado() {
    final prefs = ref.read(repositorioPreferenciasProvider).cargar();
    final raw = prefs['benchmark_results'];
    if (raw is Map<String, Object?>) {
      state = state.copyWith(resultado: BenchmarkResult.fromMap(raw));
    }
  }

  Future<void> ejecutar() async {
    if (state.ejecutando) return;
    state = BenchmarkEstado(ejecutando: true);

    final motor = ref.read(motorTtsProvider);
    final voiceConfig = ref.read(repositorioPreferenciasProvider)
        .cargarPreferenciasTyped().voiceConfig;
    final useCase = RunBenchmark(motor: motor, logger: ref.read(domainLoggerProvider));

    try {
      final resultado = await useCase.ejecutar(
        voiceConfig: voiceConfig,
        onProgreso: (paso, total, tamanio) {
          state = state.copyWith(pasoActual: paso, tamanioActual: tamanio);
        },
        debeDetenerse: () => state.cancelado,
      );

      if (state.cancelado) {
        state = BenchmarkEstado(cancelado: true);
        return;
      }

      // Persist
      final prefsRepo = ref.read(repositorioPreferenciasProvider);
      final datos = prefsRepo.cargar();
      datos['benchmark_results'] = resultado.toMap();
      prefsRepo.guardar(datos);

      state = BenchmarkEstado(resultado: resultado);
    } catch (e) {
      state = BenchmarkEstado(error: e.toString());
    }
  }

  void cancelar() {
    state = state.copyWith(cancelado: true);
  }
}
```

## Estimation Algorithm

**Input:** `BenchmarkResult` (map of char_count → ms) + `int textoChars`

**Algorithm:**
1. If `tamanios` is empty → return `null`
2. Compute `avgMsPerChar = (1/N) × Σ(tamanios[k] / k)` for each entry k
3. Return `textoChars × avgMsPerChar / 1000.0` (seconds)

**Example:** `{1500: 2300, 3000: 4500, ...}` → avg ≈ 1.53 ms/char → 6000 chars ≈ 9.2s

**Display:** `"Tiempo estimado: ~{X} min {Y}s"` (formatted: minutes when >60, else seconds).

## Storage Format

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

**Read:** `prefsRepo.cargar()['benchmark_results'] as Map?` → `BenchmarkResult.fromMap()`
**Write:** Load map, set key, `prefsRepo.guardar(map)`. Same pattern as `HomeController.build()` reads raw prefs.

## Data Flow Diagrams

### Benchmark Execution Flow

```
User taps "Ejecutar benchmark"
         │
         ▼
BenchmarkController.ejecutar()
         │
         ├── 1. Read VoiceConfig from preferences
         ├── 2. Create RunBenchmark(motor, logger)
         ├── 3. Call useCase.ejecutar(voiceConfig, onProgreso, debeDetenerse)
         │         │
         │         ├── for each size [1500, 3000, 5000, 7500, 10000, 15000]:
         │         │      ├── debeDetenerse()? → break
         │         │      ├── lorem.substring(0, N)
         │         │      ├── segmentarTexto(texto)
         │         │      ├── for each segment:
         │         │      │      └── motor.sintetizar(seg, steps, speed, lang)  ← discard audio
         │         │      ├── record stopwatch.elapsedMilliseconds
         │         │      └── onProgreso(paso, 6, N) → update state
         │         │
         │         └── return BenchmarkResult
         │
         ├── 4. Persist: cargar prefs → set benchmark_results → guardar
         └── 5. state = BenchmarkEstado(resultado: result)
```

### Estimation Flow (in HomeController)

```
Files selected
    │
    ▼
HomeController reads benchmark_results from prefs
    │
    ▼
Sum totalChars across selected files
    │
    ▼
estimarTiempo(benchmark, totalChars) → double? seconds
    │
    ├── null → hide estimate line
    └── double → format "~X min Ys" → display in status area
```

### UI State Transitions

```
    ┌────────────┐
    │   idle     │  ← initial / after cancel
    └─────┬──────┘
          │ ejecutar()
          ▼
    ┌────────────┐
    │ejecutando  │  pasoActual: 1..6
    │            │  tamanioActual: 1500..15000
    └──┬────┬────┘
       │    │
       │    │ cancelar()
       │    ▼
       │  ┌────────────┐
       │  │ cancelado   │ → _cargarResultado() → idle with previous result
       │  └────────────┘
       │
       ▼
    ┌────────────┐
    │ resultado   │  BenchmarkResult persisted
    └────────────┘
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | **Create** | Entity with `tamanios`, `voiceConfig`, `fecha`, `toMap`/`fromMap`, `avgMsPerChar`, `avgCharsPerSec` |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | **Create** | Pure use case: iterates 6 sizes, segments text, times `sintetizar()`, returns `BenchmarkResult` |
| `lib/features/benchmark/domain/use_cases/estimar_tiempo.dart` | **Create** | Pure function: `estimarTiempo(benchmark, textoChars) → double?` |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | **Create** | `Notifier<BenchmarkEstado>` with `ejecutar()`, `cancelar()`, `_cargarResultado()` |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | **Create** | UI: status card, run button, progress indicator, results table, cancel button |
| `lib/features/convert/domain/use_cases/procesar_archivo.dart` | **Modify** | Return `ProcesarResultado` instead of `ResultadoProceso`; add `ProcesarResultado` class |
| `lib/features/convert/presentation/controllers/home_controller.dart` | **Modify** | Read `ProcesarResultado` fields; compute total chars for estimation; display estimated time |
| `lib/features/settings/presentation/screens/settings_screen.dart` | **Modify** | Add benchmark `_SeccionCard` before "Acerca de" |
| `lib/presentation/routing/app_router.dart` | **Modify** | Add `Rutas.benchmark = '/benchmark'` + `GoRoute` |
| `lib/presentation/controllers/providers.dart` | **Modify** | Add `benchmarkControllerProvider` + `runBenchmarkProvider` |
| `lib/presentation/l10n/app_es.arb` | **Modify** | Add 14 benchmark + estimation i18n strings |
| `lib/presentation/l10n/app_en.arb` | **Modify** | Add 14 benchmark + estimation i18n strings |
| `test/features/benchmark/domain/use_cases/run_benchmark_test.dart` | **Create** | Unit test with fake `MotorTts` |
| `test/features/benchmark/domain/use_cases/estimar_tiempo_test.dart` | **Create** | Unit test for estimation logic |

## Integration Points

### A. `procesar_archivo.dart` — Return type change

```dart
// Add BEFORE the enum (after imports):
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

// Change return type of procesar():
Future<ProcesarResultado> procesar(...) async {
  // ... existing code ...

  // Instead of: return ResultadoProceso.ok;
  // Compute total audio duration:
  var duracionTotal = 0.0;
  for (final formato in formatosUnicos) {
    final ruta = '$rutaBase.$formato';
    duracionTotal += await _exportador.duracionAudio(ruta);
  }
  return ProcesarResultado(
    estado: ResultadoProceso.ok,
    segmentos: segmentos.length,
    duracionAudioSeg: duracionTotal,
  );

  // Same for error/omitido returns:
  // return ProcesarResultado(estado: ResultadoProceso.error, segmentos: 0, duracionAudioSeg: 0);
  // return ProcesarResultado(estado: ResultadoProceso.omitido, segmentos: 0, duracionAudioSeg: 0);
}
```

### B. `home_controller.dart` — Consume ProcesarResultado

In the processing loop (line ~445-466), change:
```dart
final resultado = await useCase.procesar(...);
// resultado is now ProcesarResultado
switch (resultado.estado) {  // was: switch (resultado)
  case ResultadoProceso.ok:
    _appendLog(t.log_archivo_fin(i + 1, totalArchivos));
    _appendLog('  Segmentos: ${resultado.segmentos}, Audio: ${resultado.duracionAudioSeg.toStringAsFixed(1)}s');
    exitos++;
    // Accumulate for estimation:
    totalSegmentos += resultado.segmentos;
    totalDuracionAudio += resultado.duracionAudioSeg;
  // ... same for omitido/error
}
```

Add estimation display after the processing loop (after line ~503):
```dart
// After processing, show estimation if benchmark exists
final benchmarkData = prefs['benchmark_results'];
if (benchmarkData is Map<String, Object?>) {
  final benchmark = BenchmarkResult.fromMap(benchmarkData);
  final totalChars = _calcularTotalChars(seleccion); // sum of archivo.titulo length or use file size
  final estimated = estimarTiempo(benchmark: benchmark, textoChars: totalChars);
  if (estimated != null) {
    _appendLog('Estimado (benchmark): ${_formatearTiempo(t, estimated)}');
  }
}
```

### C. `settings_screen.dart` — Add benchmark card

Insert before the `_SeccionCard(titulo: t.acerca_de, ...)` (line 127):
```dart
_BenchmarkSectionCard(),
```

Where `_BenchmarkSectionCard` is a new `ConsumerWidget` that:
1. Reads `benchmarkControllerProvider` for last result
2. Shows summary or "Sin datos" text
3. Has a `FilledButton.tonalIcon` navigating to `Rutas.benchmark`

### D. `app_router.dart` — New route

Add to `Rutas` class:
```dart
static const benchmark = '/benchmark';
```

Add to routes list:
```dart
GoRoute(
  path: Rutas.benchmark,
  builder: (_, __) => const BenchmarkScreen(),
),
```

### E. `providers.dart` — New providers

```dart
final benchmarkControllerProvider =
    NotifierProvider<BenchmarkController, BenchmarkEstado>(
  BenchmarkController.new,
);
```

## UI Component Tree

```
BenchmarkScreen (StatelessWidget)
  └── Scaffold
        ├── AppBar(title: Text(t.benchmark_titulo))
        └── Consumer<BenchmarkEstado>
              └── ListView
                    ├── _StatusCard
                    │     ├── Text(lastRunDate or t.benchmark_sin_datos)
                    │     └── Text(avgCharsPerSec)
                    │
                    ├── FilledButton(t.benchmark_btn_ejecutar)  [disabled while running]
                    │
                    ├── [if ejecutando]
                    │     ├── LinearProgressIndicator(value: pasoActual/6)
                    │     └── Text(t.benchmark_progreso(tamanio, paso))
                    │
                    ├── [if ejecutando]
                    │     └── TextButton(t.benchmark_btn_cancelar) → controller.cancelar()
                    │
                    ├── [if resultado != null]
                    │     └── DataTable
                    │           ├── Header: Tamaño | Tiempo | Chars/seg
                    │           └── 6 Rows (sorted by char count):
                    │                 "{N} chars" | "{X}s" | "{Y} chars/s"
                    │
                    └── [if resultado != null]
                          └── Text(t.benchmark_ultima_corrida(fecha))
```

## Testing Strategy

| Layer | What | How |
|-------|------|-----|
| Unit — entity | `BenchmarkResult.toMap`/`fromMap` roundtrip, `avgMsPerChar`, `avgCharsPerSec` | `benchmark_result_test.dart` |
| Unit — use case (RunBenchmark) | Verifies 6 sizes synthesized, timing recorded, cancellation works | `run_benchmark_test.dart` with fake `MotorTts` |
| Unit — use case (EstimarTiempo) | Linear estimation, empty benchmark returns null, positive values | `estimar_tiempo_test.dart` (pure function, no mocks) |
| Unit — controller | State transitions: idle → ejecutando → resultado, cancel, persist | `benchmark_controller_test.dart` with fake providers |

## Migration / Rollout

No database migration. The `benchmark_results` key is optional in the preferences JSON — older versions simply don't have it, and the app treats it as "no benchmark data". Rollback: revert commits + delete `lib/features/benchmark/`. The `ProcesarResultado` wrapper in `procesar_archivo.dart` is additive and backward-compatible.

## Open Questions

- None that block implementation.
