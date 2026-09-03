import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/device_spec.dart';
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

    group('toMap / fromMap', () {
      test('roundtrip preserva todos los campos', () {
        final original = _make();
        final map = original.toMap();
        final restored = BenchmarkResult.fromMap(map);

        expect(restored.tamanios, original.tamanios);
        expect(restored.voiceConfig, original.voiceConfig);
        expect(restored.fecha, original.fecha);
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

      test('toMap incluye device_spec cuando deviceSpec no es null', () {
        const device = DeviceSpec(
          brand: 'Google',
          model: 'Pixel 8',
          board: 'cheetah',
          hardware: 'cheetah',
          ramBytes: 8589934592,
        );
        final r = BenchmarkResult(
          tamanios: const {1500: 2300},
          voiceConfig: voice,
          fecha: fecha,
          deviceSpec: device,
        );

        final map = r.toMap();

        final ds = map['device_spec'] as Map<String, Object?>;
        expect(ds['brand'], 'Google');
        expect(ds['model'], 'Pixel 8');
        expect(ds['board'], 'cheetah');
        expect(ds['hardware'], 'cheetah');
        expect(ds['ram_bytes'], 8589934592);
      });

      test('roundtrip preserva los 5 campos del deviceSpec', () {
        const device = DeviceSpec(
          brand: 'Google',
          model: 'Pixel 8',
          board: 'cheetah',
          hardware: 'cheetah',
          ramBytes: 8589934592,
        );
        final r = BenchmarkResult(
          tamanios: const {1500: 2300},
          voiceConfig: voice,
          fecha: fecha,
          deviceSpec: device,
        );

        final restored = BenchmarkResult.fromMap(r.toMap());

        expect(restored.deviceSpec, isNotNull);
        expect(restored.deviceSpec!.brand, 'Google');
        expect(restored.deviceSpec!.model, 'Pixel 8');
        expect(restored.deviceSpec!.board, 'cheetah');
        expect(restored.deviceSpec!.hardware, 'cheetah');
        expect(restored.deviceSpec!.ramBytes, 8589934592);
      });

      test('fromMap sin device_spec carga deviceSpec null (backward compat)', () {
        final map = <String, Object?>{
          'tamanios': {'500': 800},
          'voice_config': {'voz': 'default', 'steps': 32, 'speed': 1.0, 'langVoz': 'es'},
          'fecha': '2026-01-01T00:00:00.000',
          // sin clave device_spec (datos pre-cambio)
        };
        final r = BenchmarkResult.fromMap(map);
        expect(r.deviceSpec, isNull);
        expect(r.tamanios, {500: 800});
      });
    });
  });
}
