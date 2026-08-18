import 'dart:typed_data';

/// Escritura de archivos de audio en múltiples formatos (contrato de dominio).
///
/// Los métodos son `Future` porque las implementaciones reales pueden delegar
/// en herramientas externas (p. ej. FFmpeg) cuya ejecución es asíncrona.
abstract class ExportadorAudio {
  /// Concatena [fragmentos] y los escribe en [ruta] con el formato indicado.
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato);

  /// Agrega [fragmentos] al final de un WAV PCM16 existente.
  ///
  /// Se usa para volcar a disco archivos enormes sin perder lo ya escrito
  /// (protección de memoria). Crea el WAV si no existe.
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta);

  /// Re-encoda un WAV existente al formato indicado.
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato);

  /// Devuelve la duración de un archivo de audio en segundos.
  ///
  /// `0.0` si no se puede leer.
  Future<double> duracionAudio(String ruta);
}
