/// Reproducción de audio local (contrato de dominio).
abstract class ReproductorAudio {
  /// Reproduce el archivo de [ruta] hasta terminar o ser interrumpido.
  Future<void> reproducir(String ruta);
}
