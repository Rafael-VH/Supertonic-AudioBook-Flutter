import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';
import 'package:supertonic_audiobook/features/editor_metadata/presentation/controllers/metadata_editor_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Pantalla del editor de metadatos MP3.
///
/// Muestra un botón para seleccionar un archivo cuando no hay ninguno cargado,
/// y un formulario completo con portada cuando se selecciona un MP3.
class MetadataEditorScreen extends ConsumerStatefulWidget {
  const MetadataEditorScreen({super.key});

  @override
  ConsumerState<MetadataEditorScreen> createState() =>
      _MetadataEditorScreenState();
}

class _MetadataEditorScreenState
    extends ConsumerState<MetadataEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(metadataEditorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.nombreArchivo ?? t.editor_metadata_cancelar),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: t.editor_metadata_cancelar,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (state.rutaArchivo != null)
            TextButton(
              onPressed: state.isSaving ? null : _guardar,
              child: Text(t.editor_metadata_guardar),
            ),
        ],
      ),
      body: state.rutaArchivo == null
          ? _buildNoFileSelected(t)
          : _buildForm(t, state),
    );
  }

  Future<void> _guardar() async {
    final t = AppLocalizations.of(context)!;
    final controller =
        ref.read(metadataEditorControllerProvider.notifier);

    await controller.guardar();

    final newState = ref.read(metadataEditorControllerProvider);
    if (!mounted) return;

    if (newState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState.error!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.editor_metadata_exito)),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildNoFileSelected(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              t.editor_metadata_sin_archivo,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _seleccionarArchivo,
              icon: const Icon(Icons.folder_open),
              label: Text(t.editor_metadata_seleccionar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations t, MetadataEditorState state) {
    final metadata = state.metadata;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Portada section
            _buildCoverArtSection(t, metadata),
            const Divider(height: 32),
            // Form fields
            TextFormField(
              initialValue: metadata.titulo,
              decoration: InputDecoration(labelText: t.editor_metadata_titulo_campo),
              onChanged: (value) => _actualizarCampo(
                (actual) => actual.copyWith(
                  titulo: value.isEmpty ? '' : value,
                  clearTitulo: value.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: metadata.artista,
              decoration: InputDecoration(labelText: t.editor_metadata_artista_campo),
              onChanged: (value) => _actualizarCampo(
                (actual) => actual.copyWith(
                  artista: value.isEmpty ? '' : value,
                  clearArtista: value.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: metadata.album,
              decoration: InputDecoration(labelText: t.editor_metadata_album_campo),
              onChanged: (value) => _actualizarCampo(
                (actual) => actual.copyWith(
                  album: value.isEmpty ? '' : value,
                  clearAlbum: value.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: metadata.pista?.toString(),
                    decoration: InputDecoration(
                      labelText: t.editor_metadata_pista_campo,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _actualizarCampo(
                      (actual) => actual.copyWith(
                        pista: int.tryParse(value),
                        clearPista: value.isEmpty,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: metadata.disco?.toString(),
                    decoration: InputDecoration(
                      labelText: t.editor_metadata_disco_campo,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _actualizarCampo(
                      (actual) => actual.copyWith(
                        disco: int.tryParse(value),
                        clearDisco: value.isEmpty,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: metadata.anio?.toString(),
                    decoration: InputDecoration(
                      labelText: t.editor_metadata_anio_campo,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _actualizarCampo(
                      (actual) => actual.copyWith(
                        anio: int.tryParse(value),
                        clearAnio: value.isEmpty,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: metadata.genero,
                    decoration: InputDecoration(
                      labelText: t.editor_metadata_genero_campo,
                    ),
                    onChanged: (value) => _actualizarCampo(
                      (actual) => actual.copyWith(
                        genero: value.isEmpty ? '' : value,
                        clearGenero: value.isEmpty,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: metadata.comentario,
              decoration: InputDecoration(
                labelText: t.editor_metadata_comentario_campo,
              ),
              maxLines: 3,
              onChanged: (value) => _actualizarCampo(
                (actual) => actual.copyWith(
                  comentario: value.isEmpty ? '' : value,
                  clearComentario: value.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
        if (state.isLoading || state.isSaving)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildCoverArtSection(AppLocalizations t, MetadatosMp3 metadata) {
    final coverArtBytes = metadata.coverArtBytes;

    if (coverArtBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.editor_metadata_cover_art,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Center(
            child: Image.memory(
              Uint8List.fromList(coverArtBytes),
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _seleccionarCoverArt,
                child: Text(t.editor_metadata_cambiar_portada),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _quitarCoverArt,
                child: Text(t.editor_metadata_quitar_portada),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.editor_metadata_cover_art,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            onPressed: _seleccionarCoverArt,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(t.editor_metadata_seleccionar),
          ),
        ),
      ],
    );
  }

  void _actualizarCampo(MetadatosMp3 Function(MetadatosMp3 actual) updater) {
    ref.read(metadataEditorControllerProvider.notifier).actualizarCampo(updater);
  }

  Future<void> _seleccionarArchivo() async {
    await ref.read(metadataEditorControllerProvider.notifier).seleccionarArchivo();
  }

  Future<void> _seleccionarCoverArt() async {
    await ref.read(metadataEditorControllerProvider.notifier).seleccionarCoverArt();
  }

  void _quitarCoverArt() {
    ref.read(metadataEditorControllerProvider.notifier).quitarCoverArt();
  }
}
