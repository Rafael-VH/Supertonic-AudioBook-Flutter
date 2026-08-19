import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

void main() {
  group('BenchmarkResult', () {
    final voice = const VoiceConfig(voz: 'M1', steps: 8, speed: 1.1, langVoz: 'es');
    final fecha = DateTime(2026, 8, 19, 12, 0);

    BenchmarkResult _make({Map<int, int>? tamanios}) {
      return BenchmarkResult(
        tamanios: tamanios ?? const {1500: 2300, 3000: 4500},
        voiceConfig: voice,
        fecha: fecha,
      );
    }

    group('constructor', () {
      test('crea con todos los campos', () {
        final r = _make();
        expect(r.tamanios, {1500: 2300, 3000: 4500});
        expect(r.voiceConfig, voice);
        expect(r.fecha, fecha);
      });
    });

    group('avgMsPerChar', () {
      test('calcula promedio correcto para datos conocidos', () {
        // 2300/1500 = 1.5333, 4500/3000 = 1.5 → avg = (1.5333+1.5)/2 ≈ 1.5167
        final r = _make();
        expect(r.avgMsPerChar, closeTo(1.51666, 0.001));
      });

      test('devuelve 0 cuando tamanios está vacío', () {
        final r = _make(tamanios: const {});
        expect(r.avgMsPerChar, 0);
      });

      test('maneja un solo dato correctamente', () {
        final r = _make(tamanios: const {1000: 1500});
        expect(r.avgMsPerChar, 1.5);
      });
    });

    group('avgCharsPerSec', () {
      test('inversa de avgMsPerChar', () {
        // avgMsPerChar ≈ 1.51666 → charsPerSec ≈ 659.35
        final r = _make();
        expect(r.avgCharsPerSec, closeTo(659.35, 0.5));
      });

      test('devuelve 0 cuando no hay datos', () {
        final r = _make(tamanios: const {});
        expect(r.avgCharsPerSec, 0);
      });
    });

    group('toMap / fromMap', () {
      test('roundtrip preserva todos los campos', () {
        final original = _make();
        final map = original.toMap();
        final restored = BenchmarkResult.fromMap(map);

        expect(restored.tamanios, original.tamanios);
        expect(restored.voiceConfig, original.voiceConfig);
        expect(restored.fecha, original.fecha);
      });

      test('tamanios serializa claves como strings', () {
        final map = _make().toMap();
        final tamanios = map['tamanios'] as Map;
        expect(tamanios.keys.first, isA<String>());
      });

      test('fromMap maneja defaults para campos faltantes', () {
        final map = <String, Object?>{
          'tamanios': {'500': 800},
          'fecha': '2026-01-01T00:00:00.000',
          // voice_config ausente
        };
        final r = BenchmarkResult.fromMap(map);
        expect(r.voiceConfig.voz, 'default');
        expect(r.voiceConfig.steps, 32);
        expect(r.voiceConfig.speed, 1.0);
        expect(r.voiceConfig.langVoz, 'es');
      });

      test('fromMap maneja tamanios vacío', () {
        final map = <String, Object?>{
          'tamanios': {},
          'voice_config': {'voz': 'F1', 'steps': 5, 'speed': 0.9, 'langVoz': 'en'},
          'fecha': '2026-06-15T10:30:00.000',
        };
        final r = BenchmarkResult.fromMap(map);
        expect(r.tamanios, isEmpty);
        expect(r.voiceConfig.voz, 'F1');
      });
    });
  });
}
