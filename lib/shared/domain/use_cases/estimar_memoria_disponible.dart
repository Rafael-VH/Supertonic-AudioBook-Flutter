import 'package:supertonic_audiobook/shared/domain/use_cases/estimar_memoria.dart';

/// Orquesta la estimación de memoria requerida para un lote de audios a
/// sintetizar, dado el espacio disponible en bytes.
///
/// Puro: sin dart:io, sin providers. El controller (presentación) lee
/// `ProcessInfo.currentRss` y pasa `availableBytes`; aquí solo se hace la
/// aritmética reutilizando la matemática ya testeada de `estimar_memoria.dart`.
class EstimarMemoriaDisponible {
  /// Devuelve (estimatedBytes, availableBytes, fraccion).
  ({int estimatedBytes, int availableBytes, double fraccion}) call({
    required List<({int chars})> stubs,
    required int availableBytes,
  }) {
    final estimatedBytes = estimarBytesLote(stubs);
    final fraccion = fraccionMemoriaRequerida(estimatedBytes, availableBytes);
    return (
      estimatedBytes: estimatedBytes,
      availableBytes: availableBytes,
      fraccion: fraccion,
    );
  }
}
