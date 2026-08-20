import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/run_benchmark.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Fijo: los 6 tamaños de la tabla de benchmark.
const benchmarkTamanios = [2500, 5000, 7500, 10000, 12500, 15000];

/// Resultado de una fila individual de benchmark.
class FilaBenchmark {
  const FilaBenchmark({required this.tiempoMs, required this.charsSeg});
  final int tiempoMs;
  final double charsSeg;
}

/// Estado de la pantalla Benchmark.
class BenchmarkEstado {
  const BenchmarkEstado({
    this.resultados = const {},
    this.filaEjecutando,
    this.cancelado = false,
    this.error,
    this.historial = const [],
  });

  /// Resultados por tamaño: clave = chars, valor = FilaBenchmark o null.
  final Map<int, FilaBenchmark?> resultados;

  /// Tamaño que se está ejecutando ahora (null = idle).
  final int? filaEjecutando;

  /// True si se solicitó cancelación.
  final bool cancelado;

  /// Mensaje de error, si lo hubo.
  final String? error;

  /// Historial de conversiones exitosas.
  final List<ConversionEntry> historial;

  bool get ejecutando => filaEjecutando != null;

  BenchmarkEstado copyWith({
    Map<int, FilaBenchmark?>? resultados,
    int? filaEjecutando,
    bool clearFilaEjecutando = false,
    bool? cancelado,
    String? error,
    bool clearError = false,
    List<ConversionEntry>? historial,
  }) {
    return BenchmarkEstado(
      resultados: resultados ?? this.resultados,
      filaEjecutando:
          clearFilaEjecutando ? null : (filaEjecutando ?? this.filaEjecutando),
      cancelado: cancelado ?? this.cancelado,
      error: clearError ? null : (error ?? this.error),
      historial: historial ?? this.historial,
    );
  }
}

/// Orquesta el ciclo de vida del benchmark por fila individual.
///
/// Cada fila (2500, 5000, ...) se ejecuta de forma independiente.
/// Los resultados se persisten en benchmark.json.
class BenchmarkController extends Notifier<BenchmarkEstado> {
  @override
  BenchmarkEstado build() {
    final historial = _cargarHistorial();
    final resultados = _cargarResultados();
    return BenchmarkEstado(
      resultados: resultados,
      historial: historial,
    );
  }

  List<ConversionEntry> _cargarHistorial() {
    final prefs = ref.read(repositorioHistorialProvider).cargar();
    final raw = prefs['conversion_history'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => ConversionEntry.fromMap(m.cast<String, Object?>()))
          .toList();
    }
    return [];
  }

  Map<int, FilaBenchmark?> _cargarResultados() {
    final prefs = ref.read(repositorioBenchmarkProvider).cargar();
    final raw = prefs['benchmark_results'];
    if (raw is Map<String, Object?>) {
      final result = BenchmarkResult.fromMap(raw);
      return {
        for (final e in result.tamanios.entries)
          e.key: FilaBenchmark(
            tiempoMs: e.value,
            charsSeg: e.key / (e.value / 1000),
          ),
      };
    }
    return {};
  }

  /// Ejecuta el benchmark para un solo tamaño (fila).
  Future<void> ejecutarFila(int tamanio) async {
    if (state.ejecutando) return;
    state = state.copyWith(
      filaEjecutando: tamanio,
      cancelado: false,
      clearError: true,
    );

    final motor = ref.read(motorTtsProvider);
    final voiceConfig = ref
        .read(repositorioPreferenciasProvider)
        .cargarPreferenciasTyped()
        .voiceConfig;
    final useCase =
        RunBenchmark(motor: motor, logger: ref.read(domainLoggerProvider));

    try {
      final resultado = await useCase.ejecutar(
        voiceConfig: voiceConfig,
        onProgreso: (_, __, ___) {},
        debeDetenerse: () => state.cancelado,
        tamanios: [tamanio],
      );

      if (state.cancelado || resultado.tamanios.isEmpty) {
        state = state.copyWith(clearFilaEjecutando: true, cancelado: false);
        return;
      }

      final ms = resultado.tamanios.values.first;
      final fila = FilaBenchmark(
        tiempoMs: ms,
        charsSeg: tamanio / (ms / 1000),
      );

      final nuevos = Map<int, FilaBenchmark?>.from(state.resultados);
      nuevos[tamanio] = fila;
      state = state.copyWith(
        resultados: nuevos,
        clearFilaEjecutando: true,
      );

      // Persistir resultado actualizado.
      _persistirResultados(nuevos);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        clearFilaEjecutando: true,
      );
    }
  }

  void _persistirResultados(Map<int, FilaBenchmark?> resultados) {
    final prefsRepo = ref.read(repositorioBenchmarkProvider);
    final datos = prefsRepo.cargar();
    final voiceConfig = ref
        .read(repositorioPreferenciasProvider)
        .cargarPreferenciasTyped()
        .voiceConfig;
    final tamanios = <String, int>{};
    for (final e in resultados.entries) {
      if (e.value != null) {
        tamanios['${e.key}'] = e.value!.tiempoMs;
      }
    }
    datos['benchmark_results'] = {
      'tamanios': tamanios,
      'voice_config': {
        'voz': voiceConfig.voz,
        'steps': voiceConfig.steps,
        'speed': voiceConfig.speed,
        'langVoz': voiceConfig.langVoz,
      },
      'fecha': DateTime.now().toIso8601String(),
    };
    prefsRepo.guardar(datos);
  }

  void cancelar() {
    state = state.copyWith(cancelado: true);
  }

  void recargar() {
    final historial = _cargarHistorial();
    final resultados = _cargarResultados();
    state = state.copyWith(
      resultados: resultados,
      historial: historial,
    );
  }
}
