import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/segmentar_texto.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

/// Lorem ipsum suficientemente largo para cubrir 30000 caracteres.
///
/// Se repite el patrón base hasta superar el tamaño máximo de prueba.
const _loremBase =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor '
    'incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis '
    'nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore '
    'eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt '
    'in culpa qui officia deserunt mollit anim id est laborum.';

final _lorem = List.filled(200, _loremBase).join();

/// Caso de uso puro: ejecuta un benchmark de rendimiento del motor TTS.
///
/// Sintetiza textos de 6 tamaños crecientes, mide el tiempo de procesamiento
/// y devuelve un [BenchmarkResult] con los resultados.
class RunBenchmark {
  RunBenchmark({required this._motor, required this._logger});

  final MotorTts _motor;
  final DomainLogger _logger;

  /// Ejecuta el benchmark con la configuración de voz dada.
  ///
  /// Llama a [onProgreso] después de completar cada tamaño.
  /// Si [debeDetenerse] devuelve `true` antes de un tamaño, retorna
  /// resultados parciales (solo los completados).
  Future<BenchmarkResult> ejecutar({
    required VoiceConfig voiceConfig,
    required void Function(int paso, int total, int tamanio) onProgreso,
    bool Function()? debeDetenerse,
    List<int>? tamanios,
  }) async {
    _logger.i('Iniciando benchmark con voz ${voiceConfig.voz}...');
    await _motor.cambiarVoz(voiceConfig.voz);

    final sizes = tamanios ?? [1500, 3000, 6000, 9000, 12000, 15000];
    final resultados = <int, int>{};
    final total = sizes.length;

    for (var i = 0; i < total; i++) {
      if (debeDetenerse != null && debeDetenerse()) {
        _logger.i('Benchmark cancelado en paso ${i + 1}/$total.');
        break;
      }

      final tamanio = sizes[i];
      final texto = _lorem.substring(0, tamanio);
      final segmentos = segmentarTexto(texto);

      final stopwatch = Stopwatch()..start();
      for (final seg in segmentos) {
        await _motor.sintetizar(
          seg,
          steps: voiceConfig.steps,
          speed: voiceConfig.speed,
          lang: voiceConfig.langVoz,
        );
      }
      stopwatch.stop();

      resultados[tamanio] = stopwatch.elapsedMilliseconds;
      _logger.i('Paso ${i + 1}/$total: $tamanio chars → ${stopwatch.elapsedMilliseconds} ms');
      onProgreso(i + 1, total, tamanio);
    }

    _logger.i('Benchmark completado: ${resultados.length} tamaños medidos.');
    return BenchmarkResult(
      tamanios: resultados,
      voiceConfig: voiceConfig,
      fecha: DateTime.now(),
    );
  }
}
