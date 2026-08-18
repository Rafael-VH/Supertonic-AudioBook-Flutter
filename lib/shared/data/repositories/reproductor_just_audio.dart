import 'package:just_audio/just_audio.dart';

import 'package:supertonic_audiobook/shared/domain/contracts/reproductor_audio.dart';

/// Implementación de [ReproductorAudio] sobre `just_audio`.
class ReproductorJustAudio implements ReproductorAudio {
  ReproductorJustAudio({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> reproducir(String ruta) async {
    await _player.setFilePath(ruta);
    await _player.play();
  }

  @override
  Future<void> pausar() => _player.pause();

  @override
  Future<void> reanudar() => _player.play();

  @override
  Future<void> detener() => _player.stop();

  /// Mapea el estado interno de `just_audio`: procesando (idle/completed) →
  /// `detenido`; si no, según `playing` → `reproduciendo` o `pausado`.
  @override
  Stream<EstadoReproduccion> get estado =>
      _player.playerStateStream.map((estado) {
        final terminal = estado.processingState == ProcessingState.idle ||
            estado.processingState == ProcessingState.completed;
        if (terminal) return EstadoReproduccion.detenido;
        return estado.playing
            ? EstadoReproduccion.reproduciendo
            : EstadoReproduccion.pausado;
      });
}
