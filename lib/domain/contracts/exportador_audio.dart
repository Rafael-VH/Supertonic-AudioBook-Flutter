import 'dart:typed_data';

/// Escritura de archivos de audio en múltiples formatos (contrato de dominio).
abstract class ExportadorAudio {
  /// Concatena [fragmentos] y los escribe en [ruta] con el formato indicado.
  void escribirAudio(List<Float32List> fragmentos, String ruta, String formato);

  /// Agrega [fragmentos] al final de un WAV PCM16 existente.
  ///
  /// Se usa para volcar a disco archivos enormes sin perder lo ya escrito
  /// (protección de memoria). Crea el WAV si no existe.
  void wavAppend(List<Float32List> fragmentos, String ruta);

  /// Re-encoda un WAV existente al formato indicado.
  void convertirDesdeWav(String rutaWav, String rutaDestino, String formato);

  /// Devuelve la duración de un archivo de audio en segundos.
  ///
  /// `0.0` si no se puede leer.
  double duracionAudio(String ruta);
}
