import 'package:supertonic_audiobook/features/benchmark/domain/entities/device_spec.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

/// Resultado de un benchmark de rendimiento del motor TTS.
///
/// Contiene los tiempos de procesamiento medidos para cada tamaño de texto
/// de prueba, junto con la configuración de voz utilizada y la fecha de
/// ejecución.
class BenchmarkResult {
  const BenchmarkResult({
    required this.tamanios,
    required this.voiceConfig,
    required this.fecha,
    this.deviceSpec,
  });

  /// Cantidad de caracteres → tiempo de procesamiento en milisegundos.
  final Map<int, int> tamanios;

  /// Configuración de voz utilizada durante el benchmark.
  final VoiceConfig voiceConfig;

  /// Fecha y hora de ejecución del benchmark.
  final DateTime fecha;

  /// Especificación del dispositivo que generó el resultado. Null en datos
  /// anteriores al cambio (backward compat).
  final DeviceSpec? deviceSpec;

  /// Tiempo promedio de procesamiento por carácter (milisegundos).
  ///
  /// Calcula `Σ(microseconds / charCount)` por entrada y divide entre el
  /// número de entradas. Devuelve `0` si no hay datos.
  double get avgMsPerChar {
    if (tamanios.isEmpty) return 0;
    var total = 0.0;
    for (final e in tamanios.entries) {
      total += e.value / e.key;
    }
    return total / tamanios.length;
  }

  /// Serializa a un `Map` plano para persistencia en `RepositorioPreferencias`.
  ///
  /// Usado en tests como fixture para construir el pref `benchmark_results`.
  /// La serialización en producción se hace inline en `BenchmarkController`.
  Map<String, Object?> toMap() => {
        'tamanios': {
          for (final e in tamanios.entries) '${e.key}': e.value,
        },
        'voice_config': {
          'voz': voiceConfig.voz,
          'steps': voiceConfig.steps,
          'speed': voiceConfig.speed,
          'langVoz': voiceConfig.langVoz,
        },
        'fecha': fecha.toIso8601String(),
        'device_spec': deviceSpec?.toMap(),
      };

  /// Deserializa desde un `Map` plano leído de `RepositorioPreferencias`.
  ///
  /// Valores faltantes o malformados se sustituyen por defaults razonables
  /// (voz `'default'`, steps `32`, speed `1.0`, langVoz `'es'`).
  factory BenchmarkResult.fromMap(Map<String, Object?> map) {
    final raw = map['tamanios'] as Map? ?? {};
    return BenchmarkResult(
      tamanios: {
        for (final e in raw.entries) int.parse(e.key as String): e.value as int,
      },
      voiceConfig: VoiceConfig(
        voz: ((map['voice_config'] as Map?)?['voz'] as String?) ?? 'default',
        steps:
            (((map['voice_config'] as Map?)?['steps'] as num?)?.toInt()) ?? 32,
        speed: (((map['voice_config'] as Map?)?['speed'] as num?)?.toDouble()) ??
            1.0,
        langVoz:
            ((map['voice_config'] as Map?)?['langVoz'] as String?) ?? 'es',
      ),
      fecha: DateTime.parse(map['fecha'] as String),
      deviceSpec: map['device_spec'] != null
          ? DeviceSpec.fromMap(map['device_spec'] as Map<String, Object?>)
          : null,
    );
  }
}
