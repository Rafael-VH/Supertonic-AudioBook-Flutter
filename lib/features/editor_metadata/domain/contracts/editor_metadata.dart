import 'package:supertonic_audiobook/features/editor_metadata/domain/entities/metadatos_mp3.dart';

/// Contrato de dominio para leer y escribir metadatos ID3 de archivos MP3.
///
/// Las implementaciones concretas (ffmpeg, mutagen-like, etc.) viven en
/// la capa de datos. El dominio solo conoce esta interfaz.
abstract class EditorMetadata {
  /// Lee los metadatos ID3 del archivo en [rutaMp3].
  Future<MetadatosMp3> leer(String rutaMp3);

  /// Escribe [metadata] en el archivo MP3 en [rutaMp3].
  Future<void> guardar(String rutaMp3, MetadatosMp3 metadata);
}
