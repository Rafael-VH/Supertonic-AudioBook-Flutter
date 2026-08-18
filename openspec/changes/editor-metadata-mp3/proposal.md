# Proposal: Editor de Metadata MP3

## Intent

Los usuarios convierten libros Markdown a audiolibros MP3 pero no pueden editar los ID3 tags (título, artista, álbum, portada) antes de compartir o archivar. Actualmente los archivos se generan con metadata mínima o predeterminada.

## Scope

### In Scope
- Leer y escribir tags ID3v2.3/v2.4 en archivos MP3 (título, artista, álbum, número de pista, número de disco, año, género, comentario, portada)
- Módulo nuevo en `lib/features/editor_metadata/` con domain/data/presentation propias
- Acción "Editar metadata" en tiles MP3 de la biblioteca (`BibliotecaBody`)
- Ruta `/editor-metadata` vía go_router

### Out of Scope
- Metadata en WAV/FLAC/OGG (futuro)
- Edición por lotes (futuro)
- Auto-completado desde nombre de archivo o APIs externas

## Capabilities

### New Capabilities
- `editor-metadata-mp3`: Lectura y escritura de tags ID3 en archivos MP3 individuales, con UI de formulario y persistencia atómica

### Modified Capabilities
- `biblioteca-audiolibros`: Nuevo action de "Editar" en tiles MP3 (requiere BIB-2 ya existente)

## Approach

Módulo nuevo aislado en `lib/features/editor_metadata/`:

| Capa | Archivo | Responsabilidad |
|------|---------|----------------|
| Domain | `domain/entities/metadatos_mp3.dart` | Entity con campos ID3 + portada |
| Domain | `domain/contracts/editor_metadata.dart` | Abstract read/write contract |
| Domain | `domain/use_cases/editar_metadata_mp3.dart` | Orquesta leer → editar → escribir |
| Data | `data/repositories/editor_metadata_id3_codec.dart` | Implementación con `id3_codec` |
| Presentation | `presentation/controllers/metadata_editor_controller.dart` | StateNotifier (Riverpod) |
| Presentation | `presentation/screens/metadata_editor_screen.dart` | Form UI |

Escritura atómica: archivo temporal → write → rename (patrón existente en `ExportadorAudio`).

Integración: icono de editar en `BibliotecaBody` tiles MP3 → navega a `/editor-metadata?ruta=...`.

## Affected Areas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `lib/features/editor_metadata/` | Nuevo módulo completo | 6 archivos nuevos (domain/data/presentation) |
| `pubspec.yaml` | Modificado | Agregar `id3_codec: ^1.0.3` |
| `lib/presentation/screens/biblioteca/biblioteca_screen.dart` | Modificado | Agregar acción editar en tiles MP3 |
| `lib/presentation/routing/app_router.dart` | Modificado | Nueva ruta `/editor-metadata` |
| `lib/main.dart` | Modificado | Provider override para EditorMetadata |

## Risks

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| `id3_codec` sin mantenimiento (3 años) | Media | Contract abstraction — swap en un archivo |
| Portada excesivamente grande | Baja | Limitar a 500KB JPEG antes de embeber |
| Escritura corrupta en crash | Baja | Patrón atómico temp→rename (ya probado) |

## Rollback Plan

1. Revertir commit del módulo (git revert)
2. Eliminar carpeta `lib/features/editor_metadata/`
3. Revertir cambios en `pubspec.yaml`, router, biblioteca, main.dart
4. El módulo es completamente aislado — no hay dependencias cruzadas con features existentes

## Dependencies

- `id3_codec: ^1.0.3` (nueva — pure Dart ID3 reader/writer)
- Existentes: `flutter_riverpod`, `go_router`, `flutter_localizations`

## Success Criteria

- [ ] Tags ID3 leídos correctamente de un MP3 existente
- [ ] Tags escritos y verificables tras guardado
- [ ] Portada embebida y visible en reproductores externos
- [ ] Escritura atómica (sin corrupción en interrupt)
- [ ] Test unitarios de domain pasan con fakes
- [ ] Test de integración con `id3_codec` pasan (read→write→read roundtrip)
- [ ] Navegación desde biblioteca hasta editor funciona
- [ ] `flutter analyze` sin errores
