import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/run_benchmark.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

/// Estado de la pantalla Benchmark.
///
/// Modela las transiciones: idle → ejecutando → resultado / error / cancelado.
class BenchmarkEstado {
  const BenchmarkEstado({
    this.ejecutando = false,
    this.pasoActual = 0,
    this.tamanioActual = 0,
    this.resultado,
    this.cancelado = false,
    this.error,
  });

  /// True mientras se ejecuta el benchmark.
  final bool ejecutando;

  /// Paso actual (1..6).
  final int pasoActual;

  /// Tamaño de texto actualmente en procesamiento (chars).
  final int tamanioActual;

  /// Último resultado persistido.
  final BenchmarkResult? resultado;

  /// True si el usuario canceló la ejecución.
  final bool cancelado;

  /// Mensaje de error, si lo hubo.
  final String? error;

  BenchmarkEstado copyWith({
    bool? ejecutando,
    int? pasoActual,
    int? tamanioActual,
    BenchmarkResult? resultado,
    bool? cancelado,
    String? error,
  }) {
    return BenchmarkEstado(
      ejecutando: ejecutando ?? this.ejecutando,
      pasoActual: pasoActual ?? this.pasoActual,
      tamanioActual: tamanioActual ?? this.tamanioActual,
      resultado: resultado ?? this.resultado,
      cancelado: cancelado ?? this.cancelado,
      error: error ?? this.error,
    );
  }
}

/// Orquesta el ciclo de vida del benchmark: idle → ejecutando → resultado.
///
/// Traduce eventos de UI a llamadas al caso de uso [RunBenchmark] y persiste
/// el resultado via [RepositorioPreferencias].
class BenchmarkController extends Notifier<BenchmarkEstado> {
  @override
  BenchmarkEstado build() {
    final resultado = _cargarResultado();
    return BenchmarkEstado(resultado: resultado);
  }

  BenchmarkResult? _cargarResultado() {
    final prefs = ref.read(repositorioPreferenciasProvider).cargar();
    final raw = prefs['benchmark_results'];
    if (raw is Map<String, Object?>) {
      return BenchmarkResult.fromMap(raw);
    }
    return null;
  }

  Future<void> ejecutar() async {
    if (state.ejecutando) return;
    state = BenchmarkEstado(ejecutando: true);

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
        onProgreso: (paso, total, tamanio) {
          state = state.copyWith(pasoActual: paso, tamanioActual: tamanio);
        },
        debeDetenerse: () => state.cancelado,
      );

      if (state.cancelado) {
        state = const BenchmarkEstado(cancelado: true);
        return;
      }

      // Persist
      final prefsRepo = ref.read(repositorioPreferenciasProvider);
      final datos = prefsRepo.cargar();
      datos['benchmark_results'] = resultado.toMap();
      prefsRepo.guardar(datos);

      state = BenchmarkEstado(resultado: resultado);
    } catch (e) {
      state = BenchmarkEstado(error: e.toString());
    }
  }

  void cancelar() {
    state = state.copyWith(cancelado: true);
  }
}
