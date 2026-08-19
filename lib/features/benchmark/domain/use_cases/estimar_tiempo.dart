import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';

/// Estima el tiempo de procesamiento (en segundos) para una cantidad de
/// caracteres dada, usando la regresión lineal simple del benchmark.
///
/// Devuelve `null` si el [benchmark] no tiene datos.
double? estimarTiempo({
  required BenchmarkResult benchmark,
  required int textoChars,
}) {
  if (benchmark.tamanios.isEmpty) return null;
  return textoChars * benchmark.avgMsPerChar / 1000.0;
}
