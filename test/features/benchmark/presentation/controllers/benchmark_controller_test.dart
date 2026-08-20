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
          repositorioBenchmarkProvider.overrideWithValue(preferencias),
          repositorioHistorialProvider.overrideWithValue(preferencias),
          motorTtsProvider.overrideWithValue(motor),
          domainLoggerProvider.overrideWithValue(NoOpLogger()),
        ],
      );
    }

    test('estado inicial es idle con resultados vacíos', () {
      final container = crearContenedor();
      final estado = container.read(benchmarkControllerProvider);

      expect(estado.ejecutando, isFalse);
      expect(estado.filaEjecutando, isNull);
      expect(estado.cancelado, isFalse);
      expect(estado.error, isNull);
      expect(estado.resultados, isEmpty);
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
    });

    test('historial vacío cuando no hay prefs', () {
      final container = crearContenedor();
      final estado = container.read(benchmarkControllerProvider);
      expect(estado.historial, isEmpty);
    });

    test('build carga resultados previos desde preferencias', () {
      final benchmark = BenchmarkResult(
        tamanios: {2500: 3000, 5000: 6000},
        voiceConfig: const VoiceConfig(voz: 'M1'),
        fecha: DateTime(2026, 8, 20),
      );
      final container = crearContenedor(prefs: {
        'benchmark_results': benchmark.toMap(),
      });
      final estado = container.read(benchmarkControllerProvider);

      expect(estado.resultados.length, 2);
      expect(estado.resultados[2500]!.tiempoMs, 3000);
      expect(estado.resultados[5000]!.tiempoMs, 6000);
      expect(estado.resultados[2500]!.charsSeg, closeTo(833.3, 0.1));
    });

    test('ejecutarFila ejecuta un solo tamaño', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutarFila(2500);

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.filaEjecutando, isNull);
      expect(estado.resultados.containsKey(2500), isTrue);
      expect(estado.resultados[2500], isNotNull);
      expect(estado.resultados[2500]!.tiempoMs, greaterThan(0));
      expect(estado.resultados[2500]!.charsSeg, greaterThan(0));
    });

    test('ejecutarFila persiste el resultado', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutarFila(5000);

      final guardado = preferencias.datos['benchmark_results'];
      expect(guardado, isA<Map>());
      final map = guardado as Map;
      expect(map.containsKey('tamanios'), isTrue);
      expect(map.containsKey('fecha'), isTrue);
    });

    test('ejecutarFila no afecta otras filas', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutarFila(2500);

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.resultados.containsKey(5000), isFalse);
      expect(estado.resultados.containsKey(7500), isFalse);
    });

    test('ejecutarFila no hace nada si ya está ejecutando', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      motor.esperaVoz = Completer<void>();
      final futuro1 = controller.ejecutarFila(2500);
      await Future<void>.delayed(Duration.zero);

      // Try second fila while first is running — should be a no-op
      await controller.ejecutarFila(5000);

      motor.esperaVoz!.complete();
      await futuro1;

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.resultados.containsKey(5000), isFalse);
    });

    test('cancelar detiene la ejecución', () async {
      final container = crearContenedor();
      final controller = container.read(benchmarkControllerProvider.notifier);

      motor.esperaVoz = Completer<void>();
      final futuro = controller.ejecutarFila(2500);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(benchmarkControllerProvider).ejecutando, isTrue);

      controller.cancelar();
      motor.esperaVoz!.complete();
      await futuro;

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
    });

    test('error en ejecución se refleja en el estado', () async {
      final container = ProviderContainer(
        overrides: [
          repositorioPreferenciasProvider
              .overrideWithValue(PreferenciasMemoria()),
          repositorioBenchmarkProvider
              .overrideWithValue(PreferenciasMemoria()),
          repositorioHistorialProvider
              .overrideWithValue(PreferenciasMemoria()),
          motorTtsProvider.overrideWithValue(_MotorQueFalla()),
          domainLoggerProvider.overrideWithValue(NoOpLogger()),
        ],
      );
      final controller =
          container.read(benchmarkControllerProvider.notifier);

      await controller.ejecutarFila(2500);

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.ejecutando, isFalse);
      expect(estado.error, isNotNull);
    });

    test('recargar actualiza resultados e historial', () async {
      final entry = ConversionEntry(
        nombreArchivo: 'nuevo.md',
        caracteres: 2000,
        segmentos: 10,
        duracionAudioSeg: 20.0,
        fecha: DateTime(2026, 8, 20),
      );
      final container = crearContenedor(prefs: {
        'conversion_history': [entry.toMap()],
      });
      final controller = container.read(benchmarkControllerProvider.notifier);

      controller.recargar();

      final estado = container.read(benchmarkControllerProvider);
      expect(estado.historial.length, 1);
      expect(estado.historial.first.nombreArchivo, 'nuevo.md');
    });

    test('copyWith preserva campos', () {
      final entry = ConversionEntry(
        nombreArchivo: 'a.md',
        caracteres: 500,
        segmentos: 2,
        duracionAudioSeg: 5.0,
        fecha: DateTime(2026, 1, 1),
      );
      const original = BenchmarkEstado();
      final modified = original.copyWith(
        historial: [entry],
      );
      expect(modified.historial.length, 1);
      expect(modified.ejecutando, isFalse);
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
