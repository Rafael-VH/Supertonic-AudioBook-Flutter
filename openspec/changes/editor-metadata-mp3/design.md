# Design: Editor de Metadata MP3

## Technical Approach

Módulo aislado en `lib/features/editor_metadata/` con capas domain/data/presentation propias. El entry point es el **segundo botón del HomeScreen** (reemplaza "Próximamente"), que navega a `/editor-metadata`. La screen ofrece un picker de archivos MP3 (ya disponible `file_picker` v11.0.3 en el proyecto). Se usa `id3_codec` para leer/escribir tags ID3v2. El controller sigue el patrón `Notifier<T>` del proyecto (igual que `BibliotecaController`). Escritura atómica: `.tmp` → `rename` (patrón de `ExportadorAudioFfmpeg`).

## Architecture Decisions

| # | Decisión | Alternativas | Rationale |
|---|----------|--------------|-----------|
| D1 | Módulo en `lib/features/editor_metadata/` con domain/data/presentation internas | Archivos sueltos en `lib/domain/`, `lib/data/`, `lib/presentation/` | El proyecto no tiene `features/` aún; el usuario lo especifica explícitamente. Futuros features pueden seguir el mismo patrón. |
| D2 | `dart:io` permitido en domain (entity `Uint8List` para cover art) | Separar cover art como tipo propio sin `dart:io` | `procesar_archivo.dart` y `modelo_gestor.dart` ya importan `dart:io` en domain. La regla es flexible en este proyecto. `Uint8List` es `dart:typed_data`, no `dart:io`. |
| D3 | Controller como `Notifier<MetadataEditorEstado>` (no `StateNotifier`) | `StateNotifier` | Todos los controllers del proyecto usan `Notifier<T>` (ver `BibliotecaController`, `HomeController`). Consistencia > preferencia personal. |
| D4 | `file_picker` para seleccionar MP3 e imágenes | Canales nativos / picker custom | `file_picker` ya está en `pubspec.yaml` (v11.0.3), ya usado en 4 screens del proyecto. |
| D5 | Provider de contrato con `throw UnimplementedError` + override en `main.dart` | Provider directo con implementación concreta | Patrón establecido: todos los contratos (`motorTtsProvider`, `exportadorAudioProvider`, etc.) siguen esta convención. |
| D6 | L10n: claves `editor_metadata_*` nuevas, sin renombrar existentes | Reutilizar `home_proximamente` | El botón cambia de función; las claves viejas se mantienen para "Editor de voz" (tercer botón). |

## Data Flow

```
HomeScreen ──onTap──► context.push(Rutas.editorMetadata)
                              │
                    MetadataEditorScreen
                              │ ref.watch(controllerProvider)
                              ▼
                  MetadataEditorController (Notifier<MetadataEditorEstado>)
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      seleccionarArchivo  EditarMetadataMp3  guardar()
      (file_picker)       (use case)         (use case)
              │               │               │
              ▼               ▼               ▼
      FilePicker.platform  EditorMetadata   EditorMetadata
      .pickFiles()         .leer(ruta)      .guardar(ruta, meta)
                              │               │
                              ▼               ▼
                      EditorMetadataId3Codec (data)
                      id3_codec + File.rename
```

## File Changes

| Archivo | Acción | Descripción |
|---------|--------|-------------|
| `lib/features/editor_metadata/domain/entities/metadatos_mp3.dart` | Crear | Entity con campos ID3 + `copyWith` + `Equatable` |
| `lib/features/editor_metadata/domain/contracts/editor_metadata.dart` | Crear | Abstract `leer`/`guardar` + excepciones custom |
| `lib/features/editor_metadata/domain/use_cases/editar_metadata_mp3.dart` | Crear | Orquesta leer → editar → guardar vía contrato |
| `lib/features/editor_metadata/data/repositories/editor_metadata_id3_codec.dart` | Crear | Impl con `id3_codec`, escritura atómica |
| `lib/features/editor_metadata/presentation/controllers/metadata_editor_controller.dart` | Crear | `Notifier<MetadataEditorEstado>` con acciones |
| `lib/features/editor_metadata/presentation/screens/metadata_editor_screen.dart` | Crear | Formulario + picker + cover art preview |
| `lib/presentation/controllers/providers.dart` | Modificar | + `editorMetadataProvider`, `editarMetadataMp3Provider` |
| `lib/presentation/screens/home/home_screen.dart` | Modificar | Segundo botón: "Editor de metadatos" habilitado |
| `lib/presentation/routing/app_router.dart` | Modificar | + `Rutas.editorMetadata`, `GoRoute` |
| `lib/main.dart` | Modificar | + override `editorMetadataProvider` |
| `lib/presentation/l10n/app_es.arb` | Modificar | + claves `editor_metadata_*` |
| `lib/presentation/l10n/app_en.arb` | Modificar | + claves `editor_metadata_*` |

## Interfaces / Contracts

```dart
// domain/entities/metadatos_mp3.dart
class MetadatosMp3 extends Equatable {
  const MetadatosMp3({
    this.titulo, this.artista, this.album, this.pista,
    this.disco, this.anio, this.genero, this.comentario,
    this.coverArtBytes, this.coverArtMime,
  });
  final String? titulo, artista, album, genero, comentario, coverArtMime;
  final int? pista, disco, anio;
  final Uint8List? coverArtBytes;
  MetadatosMp3 copyWith({...}); // todos los campos opcionales
}

// domain/contracts/editor_metadata.dart
class MetadataReadException implements Exception {
  MetadataReadException(this.ruta);
  final String ruta;
}
class MetadataWriteException implements Exception {
  MetadataWriteException(this.ruta, [this.causa]);
  final String ruta; final Object? causa;
}

abstract class EditorMetadata {
  Future<MetadatosMp3> leer(String rutaMp3);
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata);
}

// domain/use_cases/editar_metadata_mp3.dart
class EditarMetadataMp3 {
  EditarMetadataMp3({required EditorMetadata editor});
  Future<MetadatosMp3> ejecutar(String rutaMp3);
  Future<void> aplicar(String rutaMp3, MetadatosMp3 metadata);
}

// presentation/controllers/metadata_editor_controller.dart
class MetadataEditorEstado {
  final String? rutaArchivo;
  final MetadatosMp3? metadata;
  final bool isLoading, isSaving;
  final String? error;
  bool get archivoSeleccionado => rutaArchivo != null;
  // copyWith estándar
}

class MetadataEditorController extends Notifier<MetadataEditorEstado> {
  @override MetadataEditorEstado build();
  Future<void> seleccionarArchivo();   // file_picker → MP3
  Future<void> cargar(String ruta);    // use case.leer
  void actualizarTitulo(String v);     // copyWith en metadata
  void actualizarArtista(String v);    // idem
  // ... actualizarAlbum, actualizarPista, etc.
  Future<void> seleccionarCoverArt();  // file_picker → imagen, validar JPEG ≤500KB
  Future<void> guardar();             // use case.aplicar
  void cancelar();                     // reset estado
}
```

**Data layer** (`EditorMetadataId3Codec`):
- `leer`: lee bytes del archivo, parsea con `id3_codec`, mapea a `MetadatosMp3`. `File.existsSync` → lanza `MetadataReadException`.
- `guardar`: lee MP3 original, escribe tags con `id3_codec` a `<ruta>.tmp`, `File.rename` al original. Catch → limpia `.tmp` → lanza `MetadataWriteException`.

## Testing Strategy

| Capa | Qué | Cómo |
|---|---|---|
| Unit — entity | `copyWith`, `Equatable`, campos nulos | `metadatos_mp3_test.dart` |
| Unit — use case | `ejecutar`/`aplicar` delegan al contrato | `editar_metadata_mp3_test.dart` con fake `EditorMetadata` |
| Unit — controller | Estado, `seleccionarArchivo` mock, `cargar`, `guardar`, `cancelar`, flujo de error | `metadata_editor_controller_test.dart` con `file_picker` y `EditorMetadata` fakes |
| Widget — screen | Formulario visible, campos pre-cargados, botón guardar, snackbar error | `metadata_editor_screen_test.dart` (provider overrides) |
| Unit — data | Roundtrip leer→guardar→leer con MP3 temporal | `editor_metadata_id3_codec_test.dart` (archivo real en tmp dir) |

## Migration / Rollout

No aplica. Feature completamente nueva sin datos persistentes existentes. Rollback: revert de commits + eliminar `lib/features/editor_metadata/`.

## Open Questions

- Ninguno que bloquee el diseño.
