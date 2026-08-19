import 'package:supertonic_audiobook/shared/domain/constants/producto.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';

/// Sintetiza un texto de muestra para verificar que el motor funciona.
///
/// Escribe un WAV PCM16 en [ruta] y la devuelve. Lo usa el botón **Escuchar**
/// de la interfaz (paridad con `sintetizar_muestra.py`).
class SintetizarMuestra {
  SintetizarMuestra({
    required this._motor,
    required this._exportador,
    required this._logger,
  });

  final MotorTts _motor;
  final ExportadorAudio _exportador;
  final DomainLogger _logger;

  /// Sintetiza [texto] con los pasos/velocidad por defecto del producto y
  /// escribe el resultado en [ruta]. Devuelve [ruta] (exista o no el archivo).
  /// Lanza la causa real si la síntesis falla: el llamador es quien decide
  /// cómo reportarla al usuario.
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
      _logger.i('  → Muestra escrita en $ruta (${wav.length} muestras).');
    } catch (exc) {
      _logger.e('Error al sintetizar la muestra: $exc');
      rethrow;
    }
    return ruta;
  }
}
