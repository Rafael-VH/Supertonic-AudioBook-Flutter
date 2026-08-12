import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';

import 'package:supertonic_audiobook/domain/constants/producto.dart';
import 'package:supertonic_audiobook/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/data/helpers/supertonic_helper.dart' as supertonic;

final _log = Logger();

/// Implementación de [MotorTts] sobre el helper ONNX de Supertonic.
///
/// Carga los modelos y el estilo de voz una sola vez (perezosamente) y
/// devuelve las muestras float32. La inferencia ONNX es asíncrona, así que
/// el método es `Future`, como exige el contrato.
class MotorTtsSupertonic implements MotorTts {
  MotorTtsSupertonic({
    required this.onnxDir,
    required this.voiceStylesDir,
    this.voz = defaultVoice,
  });

  /// Directorio con los modelos ONNX (tts.json + los 4 `.onnx`).
  final String onnxDir;

  /// Directorio con los estilos de voz (`voice_styles/<voz>.json`).
  final String voiceStylesDir;

  String voz;

  supertonic.TextToSpeech? _tts;
  supertonic.Style? _style;

  @override
  Future<void> cambiarVoz(String voz) async {
    if (voz == this.voz) return;
    this.voz = voz;
    // El estilo se recarga en la próxima síntesis (se construye un motor
    // nuevo por voz).
    _style = null;
  }

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    final tts = _tts ??= await supertonic.loadTextToSpeech(onnxDir);
    final style = _style ??= await supertonic.loadVoiceStyle([_rutaEstilo]);
    _log.d('Sintetizando (voz=$voz, steps=$steps, speed=$speed, lang=$lang)...');
    final resultado =
        await tts(texto, lang, style, steps, speed: speed);
    final wav = resultado['wav'];
    return Float32List.fromList((wav as List).cast<double>());
  }

  String get _rutaEstilo =>
      '$voiceStylesDir${Platform.pathSeparator}$voz.json';
}
