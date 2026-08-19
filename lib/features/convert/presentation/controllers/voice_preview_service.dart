import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/sintetizar_muestra.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/features/convert/presentation/constants/muestra_voz.dart';

/// Handles voice preview (sample playback) for the convert screen.
///
/// This class encapsulates:
/// - Loading voice style
/// - Synthesizing a sample
/// - Playing the sample
class VoicePreviewService {
  VoicePreviewService({
    required this.motorTts,
    required this.sintetizarMuestra,
    required this.reproductorAudio,
  });

  final MotorTts motorTts;
  final SintetizarMuestra sintetizarMuestra;
  final ReproductorAudio reproductorAudio;

  /// Synthesize and play a voice sample for the given voice and language.
  ///
  /// Returns a log message describing the result.
  Future<String> reproducirMuestra({
    required String voz,
    required String lang,
    required String textoMuestra,
  }) async {
    await motorTts.cambiarVoz(voz);
    final temp = await getTemporaryDirectory();
    final ruta = '${temp.path}${Platform.pathSeparator}'
        'supertonic_muestra_${voz}_$lang.wav';
    await sintetizarMuestra.generar(
      textoMuestra,
      lang: lang,
      ruta: ruta,
    );
    await reproductorAudio.reproducir(ruta);
    return 'Muestra reproduciéndose: $voz ($lang)';
  }
}
