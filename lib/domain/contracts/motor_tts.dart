import 'dart:typed_data';

import '../constants/producto.dart';

/// Abstracción del motor de síntesis de voz (contrato de dominio).
///
/// La capa de dominio define SOLO la firma; nada de lo que el dominio
/// conozca puede depender de Supertonic o de implementaciones concretas.
abstract class MotorTts {
  /// Convierte texto a audio.
  ///
  /// Devuelve las muestras float32 (1D) del audio; vacío si no se generó.
  Float32List sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = defaultLang,
  });
}
