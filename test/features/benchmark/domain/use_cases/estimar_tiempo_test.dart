import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/estimar_tiempo.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

void main() {
  group('estimarTiempo', () {
    final voice = const VoiceConfig(voz: 'M1', steps: 8, speed: 1.1, langVoz: 'es');
    final fecha = DateTime(2026, 8, 19);

    BenchmarkResult _benchmark(Map<int, int> tamanios) {
      return BenchmarkResult(tamanios: tamanios, voiceConfig: voice, fecha: fecha);
    }

    test('devuelve null cuando benchmark no tiene datos', () {
      final b = _benchmark(const {});
      final result = estimarTiempo(benchmark: b, textoChars: 5000);
      expect(result, isNull);
    });

    test('estima tiempo linealmente según avgMsPerChar', () {
      // 1000 chars en 1000 ms → 1 ms/char → 5000 chars = 5 s
      final b = _benchmark(const {1000: 1000});
      final result = estimarTiempo(benchmark: b, textoChars: 5000);
      expect(result, 5.0);
    });

    test('maneja múltiples entradas correctamente', () {
      // 1500→2300 ms, 3000→4500 ms
      // avgMsPerChar = (2300/1500 + 4500/3000)/2 = (1.5333+1.5)/2 ≈ 1.51667
      // 6000 chars → 6000 * 1.51667 / 1000 ≈ 9.1 s
      final b = _benchmark(const {1500: 2300, 3000: 4500});
      final result = estimarTiempo(benchmark: b, textoChars: 6000);
      expect(result, closeTo(9.1, 0.05));
    });

    test('devuelve 0 para 0 caracteres', () {
      final b = _benchmark(const {1000: 1000});
      final result = estimarTiempo(benchmark: b, textoChars: 0);
      expect(result, 0.0);
    });
  });
}
