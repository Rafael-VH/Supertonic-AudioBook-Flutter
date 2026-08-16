import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';

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

  /// Una descarga completada en ESTA sesión publicó `listo`: el veredicto de
  /// una verificación en vuelo (lanzada antes de la descarga) quedó obsoleto
  /// y no debe pisarlo. En cambio, el `listo` optimista que llega de la
  /// preferencia NO protege el veredicto: la verificación de fondo es la
  /// fuente de verdad y debe poder corregirlo si el modelo ya no está.
  bool _descargadoEnSesion = false;

  @override
  ModeloEstado build() {
    // Verificación de fondo: el dashboard no tiene que iniciarla a mano.
    _verificarEnBackground();
    // Optimismo persistido: si la última verificación dijo "descargado", la
    // próxima apertura lo muestra al instante (la verificación de fondo lo
    // confirma o el botón del dashboard permite corregirlo).
    final preferencias = ref.read(repositorioPreferenciasProvider).cargar();
    final descargado = preferencias['modelo_descargado'] == true;
    return ModeloEstado(verificando: true, listo: descargado);
  }

  /// Comprueba el disco sin descargar y publica el estado resultante.
  ///
  /// Fire-and-forget desde [build]: si el usuario ya inició la descarga antes
  /// de que la verificación termine, su resultado se descarta (no debe pisar
  /// `descargando: true` con un estado idle). También se descarta si la
  /// descarga ya terminó mientras la verificación hasheaba: el veredicto
  /// pre-descarga (tomado con el disco vacío) no debe borrar `listo` ni el
  /// `error` de una descarga que falló en el ínterin.
  ///
  /// El veredicto que sí se publica se persiste en preferencias
  /// (`modelo_descargado`) para que la próxima apertura muestre el último
  /// estado conocido de inmediato.
  Future<void> _verificarEnBackground() async {
    final gestor = ref.read(modeloManagerProvider);
    final ok = await gestor.verificarDisponible();
    if (!ref.mounted) return;
    if (_descargaEnCurso || state.descargando) return;
    // Carrera opuesta: la descarga pudo completarse (y publicar `listo`)
    // durante la espera de arriba; esta verificación quedó obsoleta.
    // El `listo` optimista de la preferencia NO protege: se corrige abajo.
    if (state.listo && _descargadoEnSesion) return;
    // La descarga pudo FALLAR (publicó `error`, `descargando: false`) mientras
    // la verificación hasheaba: su veredicto pre-descarga no debe borrar el
    // error terminal ni dejar el gate "idle" como si nada hubiera pasado.
    if (state.error != null) return;
    _persistirVeredicto(ok);
    state = ok
        ? const ModeloEstado(listo: true)
        : const ModeloEstado(verificando: false);
  }

  /// Re-verificación bajo demanda (botón del dashboard): limpia el veredicto
  /// cacheado y vuelve a comprobar el disco, publicando el resultado fresco.
  ///
  /// No interfiere con una descarga en curso (no hace nada si hay una).
  Future<void> verificar() async {
    if (_descargaEnCurso || state.descargando) return;
    state = state.copyWith(verificando: true, listo: false, clearError: true);
    await _verificarEnBackground();
  }

  /// Persiste el veredicto del disco en preferencias, fusionado con las
  /// claves existentes (no pisa otras preferencias).
  void _persistirVeredicto(bool ok) {
    final repo = ref.read(repositorioPreferenciasProvider);
    final preferencias = repo.cargar();
    preferencias['modelo_descargado'] = ok;
    repo.guardar(preferencias);
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
      if (_cancelada) {
        state = const ModeloEstado();
      } else {
        _descargadoEnSesion = true;
        state = const ModeloEstado(listo: true);
      }
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
