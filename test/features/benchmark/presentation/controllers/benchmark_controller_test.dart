import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';

import '../../../../support/fakes.dart';

void main() {
  group('BenchmarkController', () {
    late PreferenciasMemoria preferencias;
    late MotorFake motor;

    ProviderContainer crearContenedor({Map<String, Object>? prefs}) {
      preferencias = PreferenciasMemoria(prefs);
      motor = MotorFake();
      return ProviderContainer(
        overrides: [
          repositorioPreferenciasProvider.overrideWithValue(preferencias),
          motorTtsProvider.overrideWithValue(motor),
          domainLoggerProvider.overrideWithValue(NoOpLogger()),
        ],
      );
    }

    test('estado inicial es idle sin resultado', () {
      final container = crearContenedor();
      final estado = container.read(benchmarkControllerProvider);

      expect(estado.ejecutando, isFalse);
      expect(estado.resultado, isNull);
      expect(estado.cancelado, isFalse);
      expect(estado.error, isNull);
    });

    test('build carga resultado previo desde preferencias', () {
      final benchmark = BenchmarkResult(
        tamanios: {1500: 2000, 3000: 4000},
        voiceConfig: const VoiceConfig(voz: 'M1'),
        fecha: DateTime(2026, 8, 19),
      );

      final container = crearContenedor(prefs: {
        'benchmark_results': benchmark.toMap(),
      });
      final estado = container.read(benchmarkControllerProvider);

      expect(estado.resultado, isNotNull);
      expect(estado.resultado!.tamanios, {1500: 2000, 3000: 4000});
    });

    test('ejecutar pasa de idle a ejecutando y luego a resultado',
        () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutar();

      final resultado = container.read(benchmarkControllerProvider);
      expect(resultado.ejecutando, isFalse);
      expect(resultado.resultado, isNotNull);
      expect(resultado.resultado!.tamanios.length, 6);
      expect(resultado.error, isNull);
    });

    test('ejecutar persiste el resultado en preferencias', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutar();

      final guardado = preferencias.datos['benchmark_results'];
      expect(guardado, isA<Map>());
      final map = guardado as Map;
      expect(map.containsKey('tamanios'), isTrue);
      expect(map.containsKey('fecha'), isTrue);
    });

    test('cancelar detiene la ejecución y vuelve a idle', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      // Make motor slow so we can cancel
      motor.esperaVoz = Completer<void>();

      final futuro = controller.ejecutar();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(benchmarkControllerProvider).ejecutando, isTrue);

      controller.cancelar();
      motor.esperaVoz!.complete();
      await futuro;

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.cancelado, isTrue);
    });

    test('ejecutar no hace nada si ya está ejecutando', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      motor.esperaVoz = Completer<void>();
      final futuro1 = controller.ejecutar();
      await Future<void>.delayed(Duration.zero);

      // Try to execute again while running — should be a no-op
      await controller.ejecutar();

      motor.esperaVoz!.complete();
      await futuro1;

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.resultado, isNotNull);
    });

    test('error en ejecución se refleja en el estado', () async {
      final container = ProviderContainer(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(PreferenciasMemoria()),
          motorTtsProvider.overrideWithValue(_MotorQueFalla()),
          domainLoggerProvider.overrideWithValue(NoOpLogger()),
        ],
      );
      final controller =
          container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutar();

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.error, isNotNull);
      expect(estado.resultado, isNull);
    });

    test('resultado contiene los 6 tamaños de prueba', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutar();

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.resultado!.tamanios.keys, containsAll([
        1500, 3000, 5000, 7500, 10000, 15000,
      ]));
    });
  });
}

/// Motor that throws on synthesis — used to test error state.
class _MotorQueFalla implements MotorTts {
  @override
  Future<void> cambiarVoz(String voz) async {}

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    throw Exception('Motor no disponible');
  }
}
