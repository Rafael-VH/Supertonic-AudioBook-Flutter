import 'package:just_audio/just_audio.dart';

import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';

/// Implementación de [ReproductorAudio] sobre `just_audio`.
class ReproductorJustAudio implements ReproductorAudio {
  ReproductorJustAudio({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> reproducir(String ruta) async {
    await _player.setFilePath(ruta);
    await _player.play();
  }
}
