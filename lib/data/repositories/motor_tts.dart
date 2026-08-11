import 'dart:typed_data';

import 'package:logger/logger.dart';

import '../../domain/contracts/motor_tts.dart';
import '../helpers/supertonic_helper.dart' as supertonic;

final _log = Logger();

/// Implementación de [MotorTts] sobre el helper ONNX de Supertonic.
///
/// Carga los modelos y el estilo de voz una sola vez (perezosamente) y
/// devuelve las muestras float32. La inferencia ONNX es asíncrona, así que
/// el método es `Future`, como exige el contrato.
class MotorTtsSupertonic implements MotorTts {
  MotorTtsSupertonic({required this.onnxDir, required this.vozPath});

  /// Directorio con los modelos ONNX (tts.json + los 4 `.onnx`).
  final String onnxDir;

  /// Ruta del JSON de estilo de voz (paridad con `cfg.voz`).
  final String vozPath;

  supertonic.TextToSpeech? _tts;
  supertonic.Style? _style;

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    final tts = _tts ??= await supertonic.loadTextToSpeech(onnxDir);
    final style = _style ??= await supertonic.loadVoiceStyle([vozPath]);
    _log.d('Sintetizando (steps=$steps, speed=$speed, lang=$lang)...');
    final resultado =
        await tts(texto, lang, style, steps, speed: speed);
    final wav = resultado['wav'];
    return Float32List.fromList((wav as List).cast<double>());
  }
}
