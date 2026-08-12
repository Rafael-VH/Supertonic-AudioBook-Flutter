import 'package:logger/logger.dart';

import 'package:supertonic_audiobook/domain/constants/producto.dart';
import 'package:supertonic_audiobook/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/domain/contracts/motor_tts.dart';

final _log = Logger();

/// Sintetiza un texto de muestra para verificar que el motor funciona.
///
/// Escribe un WAV PCM16 en [ruta] y la devuelve. Lo usa el botón **Escuchar**
/// de la interfaz (paridad con `sintetizar_muestra.py`).
class SintetizarMuestra {
  SintetizarMuestra({required this._motor, required this._exportador});

  final MotorTts _motor;
  final ExportadorAudio _exportador;

  /// Sintetiza [texto] con los pasos/velocidad por defecto del producto y
  /// escribe el resultado en [ruta]. Devuelve [ruta] (exista o no el archivo).
  Future<String> generar(
    String texto, {
    String lang = defaultLang,
    required String ruta,
  }) async {
    try {
      final wav = await _motor.sintetizar(
        texto,
        steps: defaultTtsSteps,
        speed: defaultSpeed,
        lang: lang,
      );
      await _exportador.escribirAudio([wav], ruta, 'wav');
      _log.i('  → Muestra escrita en $ruta (${wav.length} muestras).');
    } catch (exc) {
      _log.e('Error al sintetizar la muestra: $exc');
    }
    return ruta;
  }
}
