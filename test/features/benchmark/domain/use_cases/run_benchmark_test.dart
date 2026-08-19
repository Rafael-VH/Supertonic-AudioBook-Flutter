import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/run_benchmark.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

// --- Fakes ---

class FakeMotorTts implements MotorTts {
  /// If non-empty, sintetizar() returns this value. Otherwise returns empty.
  final Float32List? _resultado;

  /// Records calls for verification.
  final List<(String texto, int steps, double speed, String lang)> llamadas = [];

  FakeMotorTts({Float32List? resultado})
      : _resultado = resultado ?? Float32List.fromList(List.filled(8000, 0.0));

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    llamadas.add((texto, steps, speed, lang));
    return _resultado!;
  }

  @override
  Future<void> cambiarVoz(String voz) async {}
}

class FakeLogger implements DomainLogger {
  final List<String> mensajes = [];
  @override
  void i(String m) => mensajes.add('I: $m');
  @override
  void d(String m) => mensajes.add('D: $m');
  @override
  void w(String m) => mensajes.add('W: $m');
  @override
  void e(String m) => mensajes.add('E: $m');
}

// --- Tests ---

void main() {
  group('RunBenchmark', () {
    final voice = const VoiceConfig(voz: 'M1', steps: 8, speed: 1.1, langVoz: 'es');

    test('ejecuta los 6 tamaños y retorna BenchmarkResult', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);

      final result = await useCase.ejecutar(
        voiceConfig: voice,
        onProgreso: (_, __, ___) {},
      );

      // 6 sizes: 1500, 3000, 5000, 7500, 10000, 15000
      expect(result.tamanios.length, 6);
      expect(result.tamanios.keys, containsAll([1500, 3000, 5000, 7500, 10000, 15000]));
      expect(result.voiceConfig, voice);
      expect(result.fecha, isA<DateTime>());

      // All times should be >= 0 (they're measured, so at least 0 ms)
      for (final ms in result.tamanios.values) {
        expect(ms, greaterThanOrEqualTo(0));
      }
    });

    test('llama onProgreso con cada paso', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);
      final progressos = <(int, int, int)>[];

      await useCase.ejecutar(
        voiceConfig: voice,
        onProgreso: (paso, total, tamanio) {
          progressos.add((paso, total, tamanio));
        },
      );

      expect(progressos.length, 6);
      // First progress: paso=1, total=6
      expect(progressos.first.$1, 1);
      expect(progressos.first.$2, 6);
      // Last: paso=6
      expect(progressos.last.$1, 6);
    });

    test('debeDetenerse detiene antes de completar y retorna parcial', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);
      var callCount = 0;

      final result = await useCase.ejecutar(
        voiceConfig: voice,
        onProgreso: (_, __, ___) {},
        debeDetenerse: () {
          callCount++;
          return callCount >= 2; // Stop before 2nd size
        },
      );

      // Should have at most 1 size completed (the first one runs, stop checked before 2nd)
      expect(result.tamanios.length, lessThanOrEqualTo(1));
    });

    test('usa segmentarTexto para dividir el texto', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);

      await useCase.ejecutar(
        voiceConfig: voice,
        onProgreso: (_, __, ___) {},
      );

      // Motor should have been called for segments, not whole text.
      // The 1500-char text fits in a single segment (maxCharsPerSegment = 1500),
      // so 1 call for the first size. The 3000-char text needs 2+ segments.
      // Just verify motor was called multiple times overall.
      expect(motor.llamadas.length, greaterThan(6)); // At least one per size, usually more
    });

    test('usa los parámetros de voiceConfig al sintetizar', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);
      final customVoice = const VoiceConfig(voz: 'F2', steps: 10, speed: 0.9, langVoz: 'en');

      await useCase.ejecutar(
        voiceConfig: customVoice,
        onProgreso: (_, __, ___) {},
      );

      // All sintetizar calls should use the customVoice params
      for (final (_, steps, speed, lang) in motor.llamadas) {
        expect(steps, 10);
        expect(speed, 0.9);
        expect(lang, 'en');
      }
    });

    test('debeDetenerse null permite completar todos los tamaños', () async {
      final motor = FakeMotorTts();
      final logger = FakeLogger();
      final useCase = RunBenchmark(motor: motor, logger: logger);

      final result = await useCase.ejecutar(
        voiceConfig: voice,
        onProgreso: (_, __, ___) {},
        debeDetenerse: null,
      );

      expect(result.tamanios.length, 6);
    });
  });
}
