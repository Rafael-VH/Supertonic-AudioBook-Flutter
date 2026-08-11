import 'package:logger/logger.dart';

import '../contracts/motor_tts.dart';

final _log = Logger();

/// Sintetiza un texto de muestra para verificar que el motor funciona.
///
/// Devuelve `true` si se generó audio, `false` en caso contrario. Se usa para
/// validar la configuración de voz en la interfaz (paridad con
/// `app/domain/use_cases/sintetizar_muestra.py`).
bool sintetizarMuestra(
  MotorTts motor,
  String texto, {
  required int steps,
  required double speed,
}) {
  try {
    final wav = motor.sintetizar(texto, steps: steps, speed: speed);
    final ok = wav.isNotEmpty;
    _log.i('  → Muestra ${ok ? 'generada' : 'vacía'} (${wav.length} muestras).');
    return ok;
  } catch (exc) {
    _log.e('Error al sintetizar la muestra: $exc');
    return false;
  }
}
