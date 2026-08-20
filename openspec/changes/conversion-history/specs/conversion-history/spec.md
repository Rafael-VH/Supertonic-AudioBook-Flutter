# Conversion History Specification

## Purpose

Persist per-file conversion metrics (caracteres, segmentos, duración) as a capped history, and allow users to select benchmark sizes dynamically before running benchmarks.

## Requirements

### Requirement: Conversion Metrics Persistence

After each successful file conversion, the system MUST save a `ConversionEntry` containing: file name (`nombre`), character count (`caracteres`), segment count (`segmentos`), conversion duration in seconds (`duracionSeg`), and timestamp (`fecha`). Entries MUST be stored in `RepositorioPreferencias` under the key `conversion_history` as a JSON array. Character count MUST equal `textoPlano.length` from the cleaned markdown output.

#### Scenario: Entry saved on successful conversion

- GIVEN a file conversion completes successfully
- WHEN `HomeController` receives the success result
- THEN a `ConversionEntry` with all five fields is appended to the JSON array in `conversion_history`
- AND the entry appears first in the list (most recent first)

#### Scenario: History capped at 100 entries

- GIVEN the `conversion_history` array already contains 100 entries
- WHEN a new `ConversionEntry` is appended
- THEN the oldest entry (last in the array) is removed
- AND the array contains exactly 100 entries

#### Scenario: Empty history on first use

- GIVEN no `conversion_history` key exists in preferences
- WHEN the app reads conversion history
- THEN an empty list is returned

### Requirement: Benchmark Size Selection

The system MUST present a bottom sheet with `FilterChip` multi-selection for benchmark sizes. Available sizes MUST be: 1500, 3000, 6000, 9000, 12000, 15000, 18000, 21000, 24000, 27000, 30000. Default selection MUST be [1500, 3000, 6000, 9000, 12000, 15000]. The user MUST select at least 1 size to proceed. `RunBenchmark.ejecutar()` MUST accept a `List<int> tamanios` parameter instead of a hardcoded list. The progress bar denominator MUST equal the selected size count.

#### Scenario: Default selection allows immediate run

- GIVEN the user opens the benchmark size bottom sheet
- THEN 6 chips (1500–15000) are pre-selected
- AND the run button is enabled

#### Scenario: User deselects all sizes

- GIVEN the bottom sheet is open
- WHEN the user deselects all chips
- THEN the run button is disabled
- AND the user cannot start the benchmark

#### Scenario: User selects custom set

- GIVEN the bottom sheet is open with defaults
- WHEN the user deselects 3000 and selects 21000 and 27000
- AND confirms the selection
- THEN `tamanios` = [1500, 6000, 9000, 12000, 15000, 21000, 27000]
- AND the progress bar divides by 7

### Requirement: History Display in BenchmarkScreen

The system MUST display a table in `BenchmarkScreen` with columns: "Palabras | Segmentos | Duración". Duration MUST be formatted as: `Xh - Y min - Z seg` (full), `Y min - Z seg` (if < 1h), or `Z seg` (if < 1min). History MUST be ordered most recent first. An empty state MUST be shown when no history exists.

#### Scenario: Display entries with all duration formats

- GIVEN conversion history contains 3 entries
- WHEN the benchmark screen loads
- THEN entry durations display as `2h - 5min - 30seg`, `8min - 10seg`, and `45seg`

#### Scenario: Empty history state

- GIVEN no conversion history exists
- WHEN the benchmark screen loads
- THEN an empty state message is displayed
- AND no table rows are rendered

## Non-Functional Requirements

| Requirement | Constraint |
|-------------|------------|
| Storage | JSON array in SharedPreferences; max 100 entries ≈ < 50KB |
| Serialization | `ConversionEntry` MUST have `toMap()` / `fromMap()` for JSON roundtrip |
| Performance | History load on screen init MUST complete in < 50ms (local storage) |
| l10n | All user-facing strings MUST have entries in `app_es.arb` and `app_en.arb` |
