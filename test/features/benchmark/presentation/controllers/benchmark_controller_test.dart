import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
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

    test('resultado contiene los 6 tamaños por defecto', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutar();

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.resultado!.tamanios.keys, containsAll([
        1500, 3000, 6000, 9000, 12000, 15000,
      ]));
    });

    // --- Phase 4 tests: BenchmarkEstado new fields ---

    group('BenchmarkEstado new fields', () {
      test('tamaniosDisponibles tiene 11 tamaños', () {
        final container = crearContenedor();
        final estado = container.read(benchmarkControllerProvider);
        expect(estado.tamaniosDisponibles.length, 11);
        expect(estado.tamaniosDisponibles, [
          1500, 3000, 6000, 9000, 12000, 15000, 18000, 21000, 24000, 27000,
          30000,
        ]);
      });

      test('tamaniosSeleccionados default es los 6 primeros', () {
        final container = crearContenedor();
        final estado = container.read(benchmarkControllerProvider);
        expect(estado.tamaniosSeleccionados, [1500, 3000, 6000, 9000, 12000, 15000]);
      });

      test('historial vacío cuando no hay prefs', () {
        final container = crearContenedor();
        final estado = container.read(benchmarkControllerProvider);
        expect(estado.historial, isEmpty);
      });

      test('build carga historial desde preferencias', () {
        final entry = ConversionEntry(
          nombreArchivo: 'test.md',
          caracteres: 1000,
          segmentos: 5,
          duracionAudioSeg: 10.0,
          fecha: DateTime(2026, 8, 19),
        );
        final container = crearContenedor(prefs: {
          'conversion_history': [entry.toMap()],
        });
        final estado = container.read(benchmarkControllerProvider);
        expect(estado.historial.length, 1);
        expect(estado.historial.first.nombreArchivo, 'test.md');
        expect(estado.historial.first.caracteres, 1000);
      });

      test('copyWith preserva y actualiza campos nuevos', () {
        final entry = ConversionEntry(
          nombreArchivo: 'a.md',
          caracteres: 500,
          segmentos: 2,
          duracionAudioSeg: 5.0,
          fecha: DateTime(2026, 1, 1),
        );
        const original = BenchmarkEstado();
        final modified = original.copyWith(
          tamaniosSeleccionados: const [1500, 3000],
          historial: [entry],
        );
        expect(modified.tamaniosSeleccionados, [1500, 3000]);
        expect(modified.historial.length, 1);
        // Other fields preserved
        expect(modified.ejecutando, isFalse);
        expect(modified.pasoActual, 0);
      });
    });

    group('toggleTamanio', () {
      test('agrega tamaño si no estaba seleccionado', () {
        final container = crearContenedor();
        final controller = container.read(benchmarkControllerProvider.notifier);

        controller.toggleTamanio(18000);

        final estado = container.read(benchmarkControllerProvider);
        expect(estado.tamaniosSeleccionados, contains(18000));
      });

      test('quita tamaño si estaba seleccionado', () {
        final container = crearContenedor();
        final controller = container.read(benchmarkControllerProvider.notifier);

        controller.toggleTamanio(1500);

        final estado = container.read(benchmarkControllerProvider);
        expect(estado.tamaniosSeleccionados, isNot(contains(1500)));
      });
    });

    group('ejecutar with selected sizes', () {
      test('usa tamaniosSeleccionados al ejecutar', () async {
        final container = crearContenedor();
        final controller = container.read(benchmarkControllerProvider.notifier);

        // Deselect most sizes, keep only 1500 and 3000
        controller.toggleTamanio(6000);
        controller.toggleTamanio(9000);
        controller.toggleTamanio(12000);
        controller.toggleTamanio(15000);

        await controller.ejecutar();

        final estado = container.read(benchmarkControllerProvider);
        expect(estado.resultado, isNotNull);
        expect(estado.resultado!.tamanios.keys, containsAll([1500, 3000]));
        expect(estado.resultado!.tamanios.length, 2);
      });

      test('ejecutar con todos los tamaños seleccionados', () async {
        final container = crearContenedor();
        final controller = container.read(benchmarkControllerProvider.notifier);

        // Select all 11
        for (final t in [18000, 21000, 24000, 27000, 30000]) {
          controller.toggleTamanio(t);
        }

        await controller.ejecutar();

        final estado = container.read(benchmarkControllerProvider);
        expect(estado.resultado!.tamanios.length, 11);
      });
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
