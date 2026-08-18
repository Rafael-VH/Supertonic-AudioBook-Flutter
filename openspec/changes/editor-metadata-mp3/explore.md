# Exploration: Editor de Metadata MP3

## Exploration: MP3 Metadata Editor Feature

### Current State

#### Audio Export Flow (step by step)

1. **User selects Markdown files** on the Home screen (`ConvertScreen`), chooses voice, speed, formats (wav/mp3/etc.), and output folder.
2. **`HomeController.procesar()`** persists preferences and iterates selected files.
3. **`ProcesarArchivo.procesar()`** (use case, domain layer):
   - Reads and cleans Markdown via `limpiarMarkdown()`.
   - Segments text via `segmentarTexto()`.
   - Synthesizes each segment via `MotorTts.sintetizar()` → returns `Float32List` WAV PCM16 fragments.
   - Appends silence between segments (`Float32List(silenceSamples)`).
   - Writes to a working WAV temp file via `ExportadorAudio.wavAppend()` (Dart-native `wav_io.dart`).
   - For each requested format, converts from the temp WAV via `ExportadorAudio.convertirDesdeWav()`.
   - Publishes atomic outputs: renames temp → final. WAV published last for crash safety.
4. **`ExportadorAudioFfmpeg`** (data layer, implements `ExportadorAudio`):
   - WAV: pure Dart (`wav_io.dart`), no FFmpeg.
   - MP3/OGG/FLAC: FFmpeg via `ffmpeg_kit_flutter_new`. MP3 uses `libmp3lame` codec.
   - FFmpeg command: `['-y', '-i', rutaWav, '-c:a', codec, '-f', formato, rutaDestino]`
5. **Output location**: `carpeta_out` from preferences (default: `<app_documents>/audio/`). Files named `<stem>.<format>` (e.g., `milibro.mp3`).
6. **Library screen** (`BibliotecaController` + `BibliotecaScreen`): Lists `LibroGenerado` items from the output folder, grouped by stem, with MP3 > OGG > FLAC > WAV priority. Shows play/pause per tile.

#### Where MP3 files end up
- Default: `<getApplicationDocumentsDirectory()>/audio/<book_stem>.mp3`
- Custom: wherever the user configured `carpeta_out` in settings.
- Multiple formats per book can coexist: `milibro.mp3`, `milibro.wav`, etc.
- The library groups them by stem and prefers MP3.

#### Domain Entities
- **`Archivo`** (`domain/entities/archivo.dart`): Represents an input `.md` file (ruta, nombre, titulo). Pure domain — no `dart:io`.
- **`LibroGenerado`** (`domain/entities/libro_generado.dart`): Groups audio files for a book (titulo, archivos list of paths, formatoPrioritario, rutaPrioritaria helper). Pure domain — no `dart:io`.
- No entity for ID3 metadata exists yet.

#### Existing Dependencies (pubspec.yaml)
- `ffmpeg_kit_flutter_new: ^4.6.2` — FFmpeg/FFprobe, already used for audio conversion. Supports `-metadata` flag for ID3 tag writing.
- `just_audio: ^0.10.5` — Audio playback only.
- `path_provider: ^2.1.1`, `file_picker: ^11.0.3`, `shared_preferences: ^2.5.5` — File/path management.
- `flutter_riverpod: 3.4.2` — State management.
- `go_router: ^17.5.0` — Routing.
- `equatable: ^2.1.0` — Value equality for entities.

#### Architecture Patterns
- **Clean Architecture**: domain/ (entities + contracts + use_cases), data/ (implementations), presentation/ (screens + controllers/providers).
- **Composition root**: `main.dart` creates concrete implementations and overrides providers.
- **Contracts pattern**: Abstract classes in `domain/contracts/`, concrete in `data/repositories/`.
- **Riverpod**: `NotifierProvider` for controllers, `Provider` for use cases and contracts.
- **Testing**: `mocktail` for mocks, fakes in `test/support/fakes.dart`. Domain tests use fakes; FFmpeg-dependent tests are skipped in CI.

#### Settings/Output Configuration
- Preferences stored as JSON at `<app_documents>/preferencias.json` via `PreferenciasJsonLocal`.
- Keys: `carpeta_out`, `carpeta_in`, `voz`, `steps`, `speed`, `lang_voz`, `formatos`, `tema_oscuro`, `estilo`, `idioma`.
- `SettingsController` manages UI settings; `HomeController` manages conversion settings.

#### Biblioteca Screen
- Shows `LibroGenerado` tiles with book title, format badge, play/pause button.
- Empty state with navigation to Home.
- Error state with retry button.
- Each tile is a `Card` > `ListTile` showing: icon (play/pause), title, format, trailing IconButton.
- **No metadata display or editing capability exists currently.**

### Affected Areas

- **New entity needed**: `domain/entities/metadatos_mp3.dart` — ID3 metadata fields (title, artist, album, track, year, genre, coverArt bytes).
- **New contract needed**: `domain/contracts/editor_metadata.dart` — abstract interface for read/write ID3 tags.
- **New data implementation**: `data/repositories/editor_metadata_impl.dart` — concrete implementation using chosen library.
- **New use case**: `domain/use_cases/editar_metadata_mp3.dart` — orchestrates reading/writing metadata for a single MP3 file.
- **New controller**: `presentation/controllers/metadata_editor_controller.dart` — manages editor state, form fields, save/cancel.
- **New screen**: `presentation/screens/metadata_editor/metadata_editor_screen.dart` — form UI for editing metadata.
- **Biblioteca screen modification**: Add edit action to each tile (long-press or context menu) that navigates to the editor.
- **Router modification**: Add route for metadata editor (e.g., `/biblioteca/metadata`).
- **pubspec.yaml**: Add ID3 tag library dependency.
- **lib/main.dart**: May need new provider override if the editor needs a repository.

### Approaches

#### Approach 1: Pure Dart library (`id3_codec`)
- **Description**: Use `id3_codec` package for reading and writing ID3 tags entirely in Dart. No native dependencies.
- **Pros**: Pure Dart, works on all platforms, supports v1/v1.1/v2.3/v2.4, read+write+cover art, no re-encoding needed.
- **Cons**: Low download count (181/week), unverified publisher, last updated 3 years ago (1.0.3), Chinese documentation primarily, potential maintenance risk.
- **Effort**: Low — library handles all byte manipulation.

#### Approach 2: Pure Dart library (`dart_tags`)
- **Description**: Use `dart_tags` for ID3 tag parsing. Pure Dart, MIT license.
- **Pros**: Pure Dart, all platforms, 997 downloads/week, MIT license, actively maintained (0.4.1).
- **Cons**: Read-only (parsing only, no encoding/writing), would need to implement write or combine with another solution.
- **Effort**: Medium — read is easy, but writing requires additional work.

#### Approach 3: FFmpeg-based (existing dependency)
- **Description**: Use FFmpeg's `-metadata` flag via the already-installed `ffmpeg_kit_flutter_new` to write ID3 tags. FFmpeg can also read tags via `-f ffmetadata` dump.
- **Pros**: Zero new dependencies, already integrated, battle-tested, supports cover art (`-i cover.jpg`), works with existing `ExportadorAudioFfmpeg` pattern.
- **Cons**: FFmpeg re-encodes the MP3 when writing metadata (lossy re-encoding), slower, requires careful use of `-c:a copy` to avoid re-encoding (but `-metadata` with `-c:a copy` may not work reliably for all tag types on MP3).
- **Effort**: Low — FFmpeg commands are well-documented.

#### Approach 4: Hybrid — `id3_codec` for read/write + `dart_tags` as fallback for read
- **Description**: Use `id3_codec` as primary for both reading and writing ID3 tags. It handles v1, v1.1, v2.3, v2.4 with encode/decode.
- **Pros**: Pure Dart, no re-encoding, full read+write+cover art, simple API.
- **Cons**: Single library dependency, unverified publisher (risk mitigation: pin version, test thoroughly).
- **Effort**: Low.

### Recommendation

**Approach 4 (id3_codec) — with architecture that abstracts the implementation behind a contract.**

Rationale:
1. `id3_codec` is the only library that provides both **read** and **write** for ID3 v2.3/v2.4 in pure Dart. This is critical because:
   - No audio re-encoding (FFmpeg approach would lossy re-encode).
   - No platform-specific native code (cross-platform guarantee).
   - Simple API: `ID3Decoder` for read, `ID3Encoder` for write, both sync and async.
2. The contract pattern (`domain/contracts/editor_metadata.dart`) isolates the implementation — if `id3_codec` becomes unmaintained, swapping to FFmpeg-based or another library is trivial.
3. Cover art support is built-in via `MetadataV2p3Body(imageBytes: ...)`.
4. The alternative (`dart_tags`) is read-only, making it unsuitable alone.
5. FFmpeg approach causes lossy re-encoding of the MP3, which is unacceptable for a metadata editor.

**Risk mitigation for `id3_codec`**:
- Pin to `^1.0.3`.
- Write thorough tests covering read, write, roundtrip, and cover art.
- The contract abstraction means swapping later costs one file change.

### Risks

1. **`id3_codec` maintenance**: Unverified publisher, last update 3 years ago. Mitigated by contract abstraction — swapping implementations is a single-file change.
2. **Cover art size**: Large images in ID3 tags can balloon MP3 file size. Mitigate by resizing/compressing cover art before embedding (e.g., max 500KB, JPEG only).
3. **File locking on mobile**: Android/iOS may have file access restrictions for the output folder. The app already handles this via `permission_handler` for the Home screen; the same pattern applies.
4. **Multi-format limitation**: Feature scope is MP3 only. The contract design should allow extending to OGG (Vorbis comments) and FLAC (Vorbis comments) later without architectural changes.
5. **Atomic writes**: Metadata writing should use the same temp-file-then-rename pattern as audio export to prevent data loss on crash.

### Ready for Proposal

Yes — the exploration is complete. The orchestrator should:
1. Proceed to proposal with `id3_codec` as the ID3 tag library.
2. Define the contract interface with fields: title, artist, album, trackNumber, year, genre, coverArt (Uint8List?).
3. Specify the metadata editor screen as a form accessible from the library tile (long-press or edit icon).
4. Plan atomic writes (temp file → rename) matching the existing export pattern.
5. Consider the library's low download count as a risk to monitor.
