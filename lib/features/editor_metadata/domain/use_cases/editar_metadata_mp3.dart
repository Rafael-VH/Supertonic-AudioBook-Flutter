import 'package:supertonic_audiobook/features/editor_metadata/domain/contracts/editor_metadata.dart';
import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

/// Caso de uso: lectura y escritura de metadatos MP3.
///
/// Delega toda la lógica de I/O al [EditorMetadata] inyectado.
class EditarMetadataMp3 {
  const EditarMetadataMp3(this._editor);

  final EditorMetadata _editor;

  /// Lee los metadatos del MP3 en [rutaMp3].
  Future<MetadatosMp3> ejecutar(String rutaMp3) => _editor.leer(rutaMp3);

  /// Aplica [metadata] al MP3 en [rutaMp3].
  Future<void> aplicar(String rutaMp3, MetadatosMp3 metadata) =>
      _editor.guardar(rutaMp3, metadata);
}
