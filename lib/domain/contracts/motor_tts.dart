import 'dart:typed_data';

import 'package:supertonic_audiobook/domain/constants/producto.dart';

/// Abstracción del motor de síntesis de voz (contrato de dominio).
///
/// La capa de dominio define SOLO la firma; nada de lo que el dominio
/// conozca puede depender de Supertonic o de implementaciones concretas.
abstract class MotorTts {
  /// Convierte texto a audio.
  ///
  /// Devuelve las muestras float32 (1D) del audio; vacío si no se generó.
  /// Es asíncrono porque la inferencia ONNX (flutter_onnxruntime) es
  /// asíncrona por diseño.
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = defaultLang,
  });

  /// Cambia la voz activa del modelo (re-carga su estilo de voz).
  ///
  /// El modelo ONNX es único (paridad con `MotorSupertonic(voz=...)` del
  /// desktop): cambiar de voz solo re-carga el `voice_styles/<voz>.json`.
  Future<void> cambiarVoz(String voz);
}
