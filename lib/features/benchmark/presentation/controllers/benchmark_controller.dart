import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/run_benchmark.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

const _defaultTamanios = [1500, 3000, 6000, 9000, 12000, 15000];

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
    this.tamaniosDisponibles = _allSizes,
    this.tamaniosSeleccionados = _defaultTamanios,
    this.historial = const [],
  });

  static const _allSizes = [
    1500, 3000, 6000, 9000, 12000, 15000, 18000, 21000, 24000, 27000,
    30000,
  ];

  /// True mientras se ejecuta el benchmark.
  final bool ejecutando;

  /// Paso actual (1..N).
  final int pasoActual;

  /// Tamaño de texto actualmente en procesamiento (chars).
  final int tamanioActual;

  /// Último resultado persistido.
  final BenchmarkResult? resultado;

  /// True si el usuario canceló la ejecución.
  final bool cancelado;

  /// Mensaje de error, si lo hubo.
  final String? error;

  /// Todos los tamaños disponibles para selección.
  final List<int> tamaniosDisponibles;

  /// Tamaños seleccionados para la ejecución del benchmark.
  final List<int> tamaniosSeleccionados;

  /// Historial de conversiones exitosas.
  final List<ConversionEntry> historial;

  BenchmarkEstado copyWith({
    bool? ejecutando,
    int? pasoActual,
    int? tamanioActual,
    BenchmarkResult? resultado,
    bool? cancelado,
    String? error,
    List<int>? tamaniosDisponibles,
    List<int>? tamaniosSeleccionados,
    List<ConversionEntry>? historial,
  }) {
    return BenchmarkEstado(
      ejecutando: ejecutando ?? this.ejecutando,
      pasoActual: pasoActual ?? this.pasoActual,
      tamanioActual: tamanioActual ?? this.tamanioActual,
      resultado: resultado ?? this.resultado,
      cancelado: cancelado ?? this.cancelado,
      error: error ?? this.error,
      tamaniosDisponibles: tamaniosDisponibles ?? this.tamaniosDisponibles,
      tamaniosSeleccionados:
          tamaniosSeleccionados ?? this.tamaniosSeleccionados,
      historial: historial ?? this.historial,
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
    final historial = _cargarHistorial();
    return BenchmarkEstado(
      resultado: resultado,
      historial: historial,
    );
  }

  BenchmarkResult? _cargarResultado() {
    final prefs = ref.read(repositorioPreferenciasProvider).cargar();
    // Soporte legacy: benchmark_results como Map (único resultado)
    final raw = prefs['benchmark_results'];
    if (raw is Map<String, Object?>) {
      return BenchmarkResult.fromMap(raw);
    }
    // Nuevo formato: benchmark_history como Lista (múltiples corridas)
    final history = prefs['benchmark_history'];
    if (history is List && history.isNotEmpty) {
      return BenchmarkResult.fromMap(history.last as Map<String, Object?>);
    }
    return null;
  }

  List<ConversionEntry> _cargarHistorial() {
    final prefs = ref.read(repositorioPreferenciasProvider).cargar();
    final raw = prefs['conversion_history'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => ConversionEntry.fromMap(m.cast<String, Object?>()))
          .toList();
    }
    return [];
  }

  void toggleTamanio(int tamanio) {
    final actual = state.tamaniosSeleccionados.toList();
    if (actual.contains(tamanio)) {
      actual.remove(tamanio);
    } else {
      actual.add(tamanio);
    }
    state = state.copyWith(tamaniosSeleccionados: actual);
  }

  Future<void> ejecutar() async {
    if (state.ejecutando) return;
    if (state.tamaniosSeleccionados.isEmpty) return;
    state = BenchmarkEstado(
      ejecutando: true,
      tamaniosDisponibles: state.tamaniosDisponibles,
      tamaniosSeleccionados: state.tamaniosSeleccionados,
      historial: state.historial,
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
        onProgreso: (paso, total, tamanio) {
          state = state.copyWith(pasoActual: paso, tamanioActual: tamanio);
        },
        debeDetenerse: () => state.cancelado,
        tamanios: state.tamaniosSeleccionados,
      );

      if (state.cancelado) {
        state = const BenchmarkEstado(cancelado: true);
        return;
      }

      // Persist — append to history array (keep last 20 runs)
      final prefsRepo = ref.read(repositorioPreferenciasProvider);
      final datos = prefsRepo.cargar();
      final history = (datos['benchmark_history'] as List?)
              ?.map((e) => (e as Map).cast<String, Object?>())
              .toList() ??
          [];
      history.add(resultado.toMap());
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }
      datos['benchmark_history'] = history;
      // Also keep legacy key for backward compat
      datos['benchmark_results'] = resultado.toMap();
      prefsRepo.guardar(datos);

      state = BenchmarkEstado(
        resultado: resultado,
        historial: state.historial,
        tamaniosDisponibles: state.tamaniosDisponibles,
        tamaniosSeleccionados: state.tamaniosSeleccionados,
      );
    } catch (e) {
      state = BenchmarkEstado(error: e.toString());
    }
  }

  void cancelar() {
    state = state.copyWith(cancelado: true);
  }
}
