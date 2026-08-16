/// Estados observables de la reproducción (BIB-3/BIB-5).
enum EstadoReproduccion { detenido, reproduciendo, pausado }

/// Reproducción de audio local (contrato de dominio).
///
/// La UI reproduce solo vía este contrato — nunca toca `just_audio` (BIB-6).
abstract class ReproductorAudio {
  /// Reproduce el archivo de [ruta] hasta terminar o ser interrumpido.
  /// Reemplaza la fuente actual (cambio de tile incluido).
  Future<void> reproducir(String ruta);

  /// Pausa la reproducción en curso sin liberar la fuente.
  Future<void> pausar();

  /// Reanuda la reproducción pausada (sin recargar la fuente).
  Future<void> reanudar();

  /// Detiene la reproducción y vuelve al estado idle.
  Future<void> detener();

  /// Emite el estado de reproducción (idle inicial, cambios en play/pausa,
  /// fin natural del audio y errores de fuente).
  Stream<EstadoReproduccion> get estado;
}
