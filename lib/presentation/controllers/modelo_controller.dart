import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Estado del modelo de voz en el arranque (plan §5.5, gate de descarga).
class ModeloEstado {
  const ModeloEstado({
    this.verificando = false,
    this.descargando = false,
    this.bytes = 0,
    this.total = 0,
    this.archivo = '',
    this.error,
    this.listo = false,
  });

  /// Comprobando si el modelo ya está en disco.
  final bool verificando;

  /// Descarga en curso.
  final bool descargando;

  /// Bytes descargados acumulados (todos los archivos).
  final int bytes;

  /// Bytes totales del modelo.
  final int total;

  /// Archivo que se está descargando en este momento.
  final String archivo;

  /// Error de la última descarga (null si no hubo).
  final String? error;

  /// Modelo verificado y listo para usar.
  final bool listo;

  static const int _mb = 1 << 20;

  int get bytesMb => bytes ~/ _mb;
  int get totalMb => total ~/ _mb;

  /// Progreso 0..1 para la barra (0 si aún no hay total conocido).
  double get progreso => total > 0 ? (bytes / total).clamp(0.0, 1.0) : 0.0;

  ModeloEstado copyWith({
    bool? verificando,
    bool? descargando,
    int? bytes,
    int? total,
    String? archivo,
    String? error,
    bool clearError = false,
    bool? listo,
  }) {
    return ModeloEstado(
      verificando: verificando ?? this.verificando,
      descargando: descargando ?? this.descargando,
      bytes: bytes ?? this.bytes,
      total: total ?? this.total,
      archivo: archivo ?? this.archivo,
      error: clearError ? null : (error ?? this.error),
      listo: listo ?? this.listo,
    );
  }
}

/// Orquesta el gate del modelo: verifica si ya está en disco, descarga con
/// progreso si falta (resumible y cancelable) y avisa cuándo está listo.
class ModeloController extends Notifier<ModeloEstado> {
  bool _descargaEnCurso = false;
  bool _cancelada = false;

  @override
  ModeloEstado build() {
    _verificar();
    return const ModeloEstado(verificando: true);
  }

  /// Comprueba el disco sin descargar y publica el estado resultante.
  Future<void> _verificar() async {
    final gestor = ref.read(modeloManagerProvider);
    final ok = await gestor.verificarDisponible();
    if (!ref.mounted) return;
    state = ok
        ? const ModeloEstado(listo: true)
        : const ModeloEstado(verificando: false);
  }

  /// Inicia la descarga del modelo (no-op si ya está descargando o listo).
  Future<void> descargar() async {
    if (_descargaEnCurso || state.listo) return;
    _descargaEnCurso = true;
    _cancelada = false;
    final gestor = ref.read(modeloManagerProvider);
    state = state.copyWith(
      descargando: true,
      verificando: false,
      bytes: 0,
      total: 0,
      archivo: '',
      clearError: true,
    );
    try {
      await gestor.asegurarModelo(
        onProgreso: (bytes, total, archivo) {
          state = state.copyWith(bytes: bytes, total: total, archivo: archivo);
        },
      );
      if (!ref.mounted) return;
      state = _cancelada
          ? const ModeloEstado()
          : const ModeloEstado(listo: true);
    } catch (e) {
      if (!ref.mounted) return;
      state = _cancelada
          ? const ModeloEstado()
          : state.copyWith(descargando: false, error: '$e');
    } finally {
      _descargaEnCurso = false;
    }
  }

  /// Cancela la descarga en curso; el `.part` queda en disco para retomar.
  void cancelar() {
    if (!_descargaEnCurso) return;
    _cancelada = true;
    ref.read(modeloManagerProvider).cancelar();
  }
}

final modeloControllerProvider =
    NotifierProvider<ModeloController, ModeloEstado>(ModeloController.new);
