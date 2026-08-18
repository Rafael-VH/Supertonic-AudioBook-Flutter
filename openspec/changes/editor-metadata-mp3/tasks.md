# Tasks: Editor de Metadata MP3

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~550–650 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (domain+data) → PR 2 (presentation+integration) |
| Delivery strategy | ask-on-risk |
| Chain strategy | stacked-to-main |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Domain + data + provider wiring | PR 1 | Entity, contract, use case, id3_codec adapter, provider registration, pubspec, all tests |
| 2 | Presentation + integration | PR 2 | Controller, screen, L10n, router, home screen, verification |

## Phase 1: Domain Foundation

- [x] 1.1 Create `lib/features/editor_metadata/domain/entities/metadatos_mp3.dart` — immutable `MetadatosMp3` with all ID3 fields (titulo, artista, album, pista, disco, anio, genero, comentario, coverArtBytes, coverArtMime), `copyWith`, `Equatable`. Only import: `dart:typed_data`
  - _AC_: zero Flutter/dart:io imports; `copyWith` produces new instance; equality via Equatable
- [x] 1.2 Create `test/features/editor_metadata/domain/entities/metadatos_mp3_test.dart` — tests: all-null entity, copyWith each field, equality, toString
  - _AC_: passes with `flutter test`
- [x] 1.3 Create `lib/features/editor_metadata/domain/contracts/editor_metadata.dart` — abstract `EditorMetadata` with `Future<MetadatosMp3> leer(String)` and `Future<void> guardar(String, MetadatosMp3)`; custom exceptions `MetadataReadException` and `MetadataWriteException`
  - _AC_: zero Flutter/dart:io imports
- [x] 1.4 Create `lib/features/editor_metadata/domain/use_cases/editar_metadata_mp3.dart` — `EditarMetadataMp3` constructor receives `EditorMetadata`; `ejecutar(ruta)` delegates to `leer`; `aplicar(ruta, metadata)` delegates to `guardar`
  - _AC_: zero Flutter/dart:io imports; injectable contract
- [x] 1.5 Create `test/features/editor_metadata/domain/use_cases/editar_metadata_mp3_test.dart` — fake `EditorMetadata`, verify `ejecutar`/`aplicar` delegate correctly
  - _AC_: passes with `flutter test`
- [x] 1.6 Add `id3_codec: ^1.0.3` to `pubspec.yaml` dependencies; run `flutter pub get`
  - _AC_: dependency resolves without conflicts

## Phase 2: Data Implementation

- [x] 2.1 Create `lib/features/editor_metadata/data/repositories/editor_metadata_id3_codec.dart` — implements `EditorMetadata` using `id3_codec`; `leer`: File.existsSync → MetadataReadException, else parse tags → `MetadatosMp3`; `guardar`: write to `<ruta>.tmp` → `File.rename`; catch → delete .tmp → MetadataWriteException
  - _AC_: cover art read/write, atomic write pattern, no audio re-encoding
- [x] 2.2 Create `test/features/editor_metadata/data/repositories/editor_metadata_id3_codec_test.dart` — roundtrip test with real temp MP3: leer→modify→guardar→leer; test MetadataReadException on missing file; test MetadataWriteException cleanup
  - _AC_: all tests pass; temp files cleaned up

## Phase 3: Provider Wiring

- [x] 3.1 Add to `lib/presentation/controllers/providers.dart`: `editorMetadataProvider` (Provider<EditorMetadata> with UnimplementedError) + `editarMetadataMp3Provider` (composes use case with contract)
  - _AC_: follows existing provider pattern (UnimplementedError default)
- [x] 3.2 Add override in `lib/main.dart`: `editorMetadataProvider.overrideWithValue(EditorMetadataId3Codec())`
  - _AC_: composition root only imports data layer
- [x] 3.3 Create `test/features/editor_metadata/data/repositories/editor_metadata_id3_codec_test.dart` (already done in 2.2) and verify provider graph doesn't break existing tests
  - _AC_: `flutter test` green

## Phase 4: L10n + Controller

- [x] 4.1 Add keys to `lib/presentation/l10n/app_es.arb` and `app_en.arb`: `home_editor_metadata`, `home_editor_metadata_desc`, `editor_metadata_titulo`, `editor_metadata_seleccionar`, `editor_metadata_guardar`, `editor_metadata_cancelar`, field labels (`editor_metadataCampo_titulo`, `_artista`, `_album`, `_pista`, `_disco`, `_anio`, `_genero`, `_comentario`), `editor_metadata_cover_art`, `editor_metadata_exito`, `editor_metadata_error_lectura`, `editor_metadata_error_escritura`
  - _AC_: run `flutter gen-l10n` succeeds; l10n files compile
- [x] 4.2 Create `lib/features/editor_metadata/presentation/controllers/metadata_editor_controller.dart` — `Notifier<MetadataEditorEstado>` with state: metadata, rutaArchivo, nombreArchivo, isLoading, isSaving, error; actions: `seleccionarArchivo()`, `cargar(ruta)`, field updaters, `seleccionarCoverArt()`, `guardar()`, `cancelar()`
  - _AC_: imports domain only (not data); uses `editarMetadataMp3Provider`
- [x] 4.3 Create `test/features/editor_metadata/presentation/controllers/metadata_editor_controller_test.dart` — fake EditorMetadata + fake FilePicker; test: initial state, cargar sets metadata, guardar delegates, cancelar resets, error handling shows error state
  - _AC_: all tests pass

## Phase 5: Screen + Integration

- [x] 5.1 Create `lib/features/editor_metadata/presentation/screens/metadata_editor_screen.dart` — two states: file picker (no file) / metadata form (file loaded); TextFormField per field; cover art preview with change button; AppBar with Guardar/Cancelar; loading/error states via snackbar
  - _AC_: imports controllers only (not data); provider overrides in widget tree
- [x] 5.2 Add `Rutas.editorMetadata = '/editor-metadata'` to `lib/presentation/routing/app_router.dart` + GoRoute pointing to MetadataEditorScreen
  - _AC_: route navigable via `context.push`
- [x] 5.3 Update second `_FunctionCard` in `lib/presentation/screens/home/home_screen.dart`: enable it, change icon to `Icons.edit_outlined`/`Icons.edit`, change title/description to l10n keys `home_editor_metadata`/`home_editor_metadata_desc`, onTap → `context.push(Rutas.editorMetadata)`
  - _AC_: button enabled, navigates to editor
- [x] 5.4 Create `test/features/editor_metadata/presentation/screens/metadata_editor_screen_test.dart` — widget test: renders file picker initially, loads form with metadata, shows snackbar on error
  - _AC_: all tests pass

## Phase 6: Verification

- [x] 6.1 Run `flutter analyze lib test` — zero errors/warnings
- [x] 6.2 Run `flutter test` — all tests pass (existing + new)
- [x] 6.3 Verify Clean Architecture: no `data/` imports in `presentation/`; no `flutter/*` imports in `domain/`
