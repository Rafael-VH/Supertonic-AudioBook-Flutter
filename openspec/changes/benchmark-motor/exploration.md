# Exploration: Benchmark Motor TTS

## Purpose

Add a TTS benchmark/calibration module to Supertonic AudioBook. The feature runs TTS synthesis tests with Lorem ipsum text at different sizes (1500–15000 chars), measures actual processing time per test, saves results for estimation, and provides a future pathway for sending device specs with benchmark data.

## Current State

### TTS Pipeline

The TTS engine is accessed via the `MotorTts` contract (`lib/features/convert/domain/contracts/motor_tts.dart`):
- `sintetizar(texto, {steps, speed, lang})` → `Future<Float32List>` (audio samples)
- `cambiarVoz(voz)` → `Future<void>`

The synthesis loop in `ProcesarArchivo.procesar()` (line 148–172) iterates over segments, calling `motor.sintetizar()` for each, accumulating audio fragments. Processing time is measured at the file level (`DateTime.now().difference(inicio)`) but NOT per-segment.

### Text Segmentation

`segmentarTexto()` splits text into ≤1500-char chunks (`maxCharsPerSegment`). For benchmark purposes, we need to synthesize texts of specific sizes, which may or may not align with segment boundaries.

### Voice Configuration

`VoiceConfig` bundles `voz`, `steps`, `speed`, `langVoz`. These are read from preferences via `repositorioPreferenciasProvider` and used in `HomeController.build()`. The benchmark should use the **current user settings** (same voice, steps, speed, lang) so results reflect real-world performance.

### Persistence

Preferences are stored as a JSON file on disk via `PreferenciasJsonLocal` (`lib/shared/data/repositories/repositorio_preferencias.dart`). The `RepositorioPreferencias` contract provides `cargar()`/`guardar()` with a `Map<String, Object>`. There is no SharedPreferences — it's a custom JSON file.

### Settings Screen

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) uses a `ListView` with `_SeccionCard` widgets. New cards are added by appending to the `children` list. The `AcercaDeSection` is the last card — the benchmark card should go before it.

### Routing

`app_router.dart` uses `GoRouter` with routes defined in `Rutas` abstract class. New routes follow the pattern `static const name = '/name'`.

### Feature Module Pattern

Features follow Clean Architecture with domain/data/presentation layers:
```
lib/features/{feature}/
  domain/
    contracts/     (abstract classes)
    use_cases/     (business logic)
    entities/      (value objects)
  data/
    repositories/  (implementations)
  presentation/
    screens/
    controllers/   (Riverpod Notifiers)
    widgets/
```

## Affected Areas

| File | Why |
|------|-----|
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add benchmark card + navigate to benchmark screen |
| `lib/features/settings/presentation/controllers/settings_controller.dart` | Read benchmark results for display |
| `lib/presentation/routing/app_router.dart` | Add `/benchmark` route |
| `lib/presentation/controllers/providers.dart` | Add benchmark provider |
| `lib/shared/domain/entities/app_preferences.dart` | Add benchmark results to typed preferences (or separate storage) |
| `lib/presentation/l10n/app_es.arb` | Add i18n strings |
| `lib/presentation/l10n/app_en.arb` | Add i18n strings |

New files (benchmark feature):
| File | Purpose |
|------|---------|
| `lib/features/benchmark/domain/entities/benchmark_result.dart` | Result entity |
| `lib/features/benchmark/domain/use_cases/run_benchmark.dart` | Core benchmark logic |
| `lib/features/benchmark/presentation/controllers/benchmark_controller.dart` | State management |
| `lib/features/benchmark/presentation/screens/benchmark_screen.dart` | UI |

## Approaches

### Approach 1: Separate Feature Module (Clean Architecture)

Create a full `lib/features/benchmark/` module with domain/data/presentation layers following the existing pattern.

**Pros:**
- Follows existing architecture (like `modelo` feature)
- Testable: `RunBenchmark` use case can be tested with fake `MotorTts`
- Separation of concerns: benchmark logic doesn't pollute settings

**Cons:**
- More files (6+ new files)
- Heavier than needed for what's essentially a timing loop

**Effort:** Medium

### Approach 2: Inline in Settings (Controller + Screen only)

Add benchmark logic directly to `SettingsController` or a lightweight helper, with the benchmark screen as a simple widget.

**Pros:**
- Fewer files (3-4 new)
- Faster to implement

**Cons:**
- Violates Clean Architecture (presentation knows about TTS)
- Harder to test the benchmark logic in isolation
- Settings controller grows unrelated responsibilities

**Effort:** Low

### Approach 3: Hybrid — Domain use case + Presentation inline

Create a `RunBenchmark` use case in domain (testable), but keep the controller thin and embed it within the settings feature.

**Pros:**
- Testable core logic
- Minimal file count (4-5 files)
- Still respects dependency rule

**Cons:**
- Slightly less modular than a full feature

**Effort:** Low-Medium

### Approach 4: Pure function benchmark (no controller)

The benchmark is just a function that takes `MotorTts` + `VoiceConfig` and returns results. The screen manages its own state with `StatefulWidget` + `setState`.

**Pros:**
- Simplest possible implementation
- No new providers

**Cons:**
- Doesn't follow Riverpod pattern used everywhere else
- Harder to integrate with the rest of the app for future features (estimation, feedback)
- State management is ad-hoc

**Effort:** Low

## Recommendation

**Approach 3: Hybrid — Domain use case + Presentation inline**

Rationale:
- The `RunBenchmark` use case is pure domain — it only depends on `MotorTts` and `VoiceConfig`, both already in domain. It can be tested with a fake `MotorTts` that returns after a delay.
- The controller can be a simple `StateNotifier` within the benchmark feature, following the pattern of `ModeloController`.
- Benchmark results are a simple entity stored in preferences (JSON file), not worth a separate data layer.
- The feature is small enough that a full data layer would be over-engineering.

### Benchmark Result Entity

```dart
class BenchmarkResult {
  const BenchmarkResult({
    required this.tamanios,
    required this.voiceConfig,
    required this.fecha,
    required this.deviceInfo,
  });

  /// Map of char count → processing time in milliseconds
  final Map<int, int> tamanios; // {1500: 2300, 3000: 4500, ...}
  final VoiceConfig voiceConfig;
  final DateTime fecha;
  final String deviceInfo; // Future: for feedback
}
```

### Lorem Ipsum Generation

A simple utility function that generates Lorem ipsum text of exact character count by repeating a base paragraph and truncating. No library needed — just a const string and string operations.

### Storage

Store benchmark results in the existing `RepositorioPreferencias` JSON under a `benchmark_results` key. The `AppPreferences` entity can be extended OR we can use the raw `cargar()`/`guardar()` pattern (the latter is simpler and avoids changing the entity).

### Integration with Processing UI

The benchmark results can be used to estimate processing time by:
1. Linear interpolation between measured points
2. Or a simple `charsPerSecond = chars / (timeMs / 1000)` average

This estimation would be displayed in `HomeController` when the user selects files, showing an "estimated time" before processing starts.

### Settings Screen Card

Add a new `_SeccionCard` before the "Acerca de" card with:
- Title: "Benchmark" / "Calibración"
- Description text explaining what it does
- Button: "Run benchmark" / "Ejecutar benchmark"
- If results exist: show last run date and a summary table
- Navigate to `/benchmark` screen

## Risks

1. **Long execution time**: 6 text sizes × TTS synthesis could take minutes on slow devices. Must show progress and allow cancellation.
2. **Model not loaded**: Benchmark requires the model to be downloaded. The screen should check `ModeloController.listo` and redirect to model download if needed.
3. **Results accuracy**: TTS performance varies with device load, thermal state, etc. Results should be tagged with timestamp and voice config for validity.
4. **Memory pressure**: Large text synthesis (15000 chars → ~10 segments) may cause OOM on low-end devices. The benchmark should synthesize segments one at a time (like `ProcesarArchivo`) and not accumulate all audio.
5. **Estimation accuracy**: Linear interpolation from 6 data points may not be accurate for very long texts. The estimation should be marked as approximate.

## Ready for Proposal

Yes. The scope is well-defined:
- New feature module with domain use case + presentation
- 4-5 new files following existing patterns
- Integration points in settings screen and router
- Clear storage approach (existing preferences JSON)
- Risks identified and mitigatable

The orchestrator should tell the user:
1. The recommended approach (hybrid Clean Architecture)
2. The benchmark will use current voice settings (not hardcoded)
3. Results persist across sessions in the existing preferences file
4. The estimation feature (step 5 in the original request) is a separate future change
