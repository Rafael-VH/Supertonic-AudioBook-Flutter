import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Estado de la pantalla Editor de Metadatos.
class MetadataEditorState {
  const MetadataEditorState({
    this.metadata = const MetadatosMp3(),
    this.rutaArchivo,
    this.nombreArchivo,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.mensajeExito,
  });

  final MetadatosMp3 metadata;
  final String? rutaArchivo;
  final String? nombreArchivo;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? mensajeExito;

  MetadataEditorState copyWith({
    MetadatosMp3? metadata,
    String? rutaArchivo,
    bool clearRutaArchivo = false,
    String? nombreArchivo,
    bool clearNombreArchivo = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? mensajeExito,
    bool clearMensajeExito = false,
  }) {
    return MetadataEditorState(
      metadata: metadata ?? this.metadata,
      rutaArchivo:
          clearRutaArchivo ? null : (rutaArchivo ?? this.rutaArchivo),
      nombreArchivo:
          clearNombreArchivo ? null : (nombreArchivo ?? this.nombreArchivo),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      mensajeExito:
          clearMensajeExito ? null : (mensajeExito ?? this.mensajeExito),
    );
  }
}

/// Orquesta la pantalla Editor de Metadatos MP3: selección de archivo,
/// carga, edición de campos, portada, guardado y reset.
class MetadataEditorController extends Notifier<MetadataEditorState> {
  @override
  MetadataEditorState build() => const MetadataEditorState();

  /// Abre el file picker para seleccionar un MP3 y carga sus metadatos.
  Future<void> seleccionarArchivo() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (resultado == null || resultado.files.isEmpty) return;

    final archivo = resultado.files.first;
    final ruta = archivo.path;
    if (ruta == null) return;

    state = state.copyWith(
      nombreArchivo: archivo.name,
      clearError: true,
      clearMensajeExito: true,
    );
    await cargar(ruta);
  }

  /// Carga los metadatos del MP3 en [ruta].
  Future<void> cargar(String ruta) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCase = ref.read(editarMetadataMp3Provider);
      final metadata = await useCase.ejecutar(ruta);
      state = state.copyWith(
        metadata: metadata,
        rutaArchivo: ruta,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '$e',
      );
    }
  }

  /// Actualiza los metadatos de forma inmutable.
  ///
  /// [updater] recibe el valor actual y debe devolver la nueva versión.
  void actualizarCampo(MetadatosMp3 Function(MetadatosMp3 actual) updater) {
    final nueva = updater(state.metadata);
    state = state.copyWith(
      metadata: nueva,
      clearError: true,
      clearMensajeExito: true,
    );
  }

  /// Abre el file picker para seleccionar una imagen de portada (JPEG).
  Future<void> seleccionarCoverArt() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;

    final archivo = resultado.files.first;
    final bytes = archivo.bytes;
    if (bytes == null) {
      state = state.copyWith(
        error:
            'La portada debe ser JPEG y no superar 500KB.',
      );
      return;
    }

    if (bytes.length > 500 * 1024) {
      state = state.copyWith(
        error:
            'La portada debe ser JPEG y no superar 500KB.',
      );
      return;
    }

    state = state.copyWith(
      metadata: state.metadata.copyWith(
        coverArtBytes: Uint8List.fromList(bytes),
        coverArtMime: 'image/jpeg',
      ),
      clearError: true,
      clearMensajeExito: true,
    );
  }

  /// Quita la portada actual.
  void quitarCoverArt() {
    state = state.copyWith(
      metadata: state.metadata.copyWith(
        clearCoverArtBytes: true,
        clearCoverArtMime: true,
      ),
    );
  }

  /// Guarda los metadatos en el archivo MP3.
  Future<void> guardar() async {
    final ruta = state.rutaArchivo;
    if (ruta == null) {
      state = state.copyWith(error: 'No hay archivo seleccionado.');
      return;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final useCase = ref.read(editarMetadataMp3Provider);
      await useCase.aplicar(ruta, state.metadata);
      state = state.copyWith(
        isSaving: false,
        mensajeExito: 'Metadatos guardados correctamente.',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: '$e',
      );
    }
  }

  /// Limpia todo el estado.
  void reset() {
    state = const MetadataEditorState();
  }
}

final metadataEditorControllerProvider =
    NotifierProvider<MetadataEditorController, MetadataEditorState>(
      MetadataEditorController.new,
    );
