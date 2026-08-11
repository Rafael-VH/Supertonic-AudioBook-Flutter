import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/constants/producto.dart';
import '../../domain/entities/archivo.dart';
import '../constants/muestra_voz.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';

/// Mensaje de snackbar emitido por el controlador para que la pantalla lo
/// muestre (y lo limpie con `ref.listen`).
class MensajeSnackbar {
  const MensajeSnackbar(this.texto, {this.esError = false});

  final String texto;
  final bool esError;
}

/// Estado de la pantalla Home (paridad con `gui.py` del desktop).
class HomeEstado {
  const HomeEstado({
    required this.carpetaIn,
    required this.carpetaOut,
    required this.archivos,
    required this.seleccion,
    required this.voz,
    required this.steps,
    required this.speed,
    required this.langVoz,
    required this.formatos,
    required this.ejecutando,
    required this.probandoVoz,
    required this.cancelar,
    required this.progresoActual,
    required this.progresoTotal,
    required this.estado,
    required this.lineasLog,
    required this.snackbar,
  });

  final String carpetaIn;
  final String carpetaOut;
  final List<Archivo> archivos;

  /// Rutas marcadas en la lista. Vacío = "todos" (behavior de la ayuda).
  final Set<String> seleccion;

  final String voz;
  final int steps;
  final double speed;
  final String langVoz;
  final Set<String> formatos;

  final bool ejecutando;
  final bool probandoVoz;
  final bool cancelar;

  final int progresoActual;
  final int progresoTotal;

  /// Línea de estado (vacío = "Listo." del i18n).
  final String estado;

  /// Registro (log), truncado a 2500 líneas (paridad con el desktop).
  final List<String> lineasLog;

  final MensajeSnackbar? snackbar;

  HomeEstado copyWith({
    String? carpetaIn,
    String? carpetaOut,
    List<Archivo>? archivos,
    Set<String>? seleccion,
    String? voz,
    int? steps,
    double? speed,
    String? langVoz,
    Set<String>? formatos,
    bool? ejecutando,
    bool? probandoVoz,
    bool? cancelar,
    int? progresoActual,
    int? progresoTotal,
    String? estado,
    List<String>? lineasLog,
    MensajeSnackbar? snackbar,
  }) {
    return HomeEstado(
      carpetaIn: carpetaIn ?? this.carpetaIn,
      carpetaOut: carpetaOut ?? this.carpetaOut,
      archivos: archivos ?? this.archivos,
      seleccion: seleccion ?? this.seleccion,
      voz: voz ?? this.voz,
      steps: steps ?? this.steps,
      speed: speed ?? this.speed,
      langVoz: langVoz ?? this.langVoz,
      formatos: formatos ?? this.formatos,
      ejecutando: ejecutando ?? this.ejecutando,
      probandoVoz: probandoVoz ?? this.probandoVoz,
      cancelar: cancelar ?? this.cancelar,
      progresoActual: progresoActual ?? this.progresoActual,
      progresoTotal: progresoTotal ?? this.progresoTotal,
      estado: estado ?? this.estado,
      lineasLog: lineasLog ?? this.lineasLog,
      // El snackbar solo cambia cuando el controller emite uno nuevo; el resto
      // de las actualizaciones lo conservan.
      snackbar: snackbar ?? this.snackbar,
    );
  }
}

/// Orquesta la pantalla Home: carpetas, lista `.md`, selección, opciones de
/// síntesis, botón **Escuchar** y el procesamiento con registro y progreso.
///
/// Paridad con `gui.py`: persiste las claves de §6.3 al iniciar el
/// procesamiento y mantiene el throttle del log (`paso = max(1, total ~/ 20)`)
/// y el truncado a 2500 líneas.
class HomeController extends Notifier<HomeEstado> {
  @override
  HomeEstado build() {
    final prefs = ref.watch(repositorioPreferenciasProvider).cargar();
    final base = ref.watch(carpetaBaseProvider);
    final sep = Platform.pathSeparator;
    final carpetaIn =
        prefs['carpeta_in'] as String? ?? '$base${sep}archivos';
    final carpetaOut =
        prefs['carpeta_out'] as String? ?? '$base${sep}audio';
    final voz = prefs['voz'] as String? ?? defaultVoice;
    final steps =
        ((prefs['steps'] as num?)?.toInt() ?? defaultTtsSteps).clamp(5, 12);
    final speed = ((prefs['speed'] as num?)?.toDouble() ?? defaultSpeed)
        .clamp(0.7, 2.0);
    final langVoz = prefs['lang_voz'] as String? ?? defaultLang;
    final formatos =
        ((prefs['formatos'] as List?)?.cast<String>() ?? ['wav', 'mp3'])
            .toSet();

    final archivos =
        ref.read(repositorioArchivosProvider).listarArchivosMd(carpetaIn);

    return HomeEstado(
      carpetaIn: carpetaIn,
      carpetaOut: carpetaOut,
      archivos: archivos,
      seleccion: const {},
      voz: voz,
      steps: steps,
      speed: speed,
      langVoz: langVoz,
      formatos: formatos,
      ejecutando: false,
      probandoVoz: false,
      cancelar: false,
      progresoActual: 0,
      progresoTotal: 0,
      estado: '',
      lineasLog: const [],
      snackbar: null,
    );
  }

  // ------------------------------------------------------- carpetas y lista

  Future<void> examinarCarpetaIn() async {
    final carpeta = await FilePicker.getDirectoryPath();
    if (carpeta == null) return;
    state = state.copyWith(carpetaIn: carpeta);
    cargarArchivos();
  }

  Future<void> examinarCarpetaOut() async {
    final carpeta = await FilePicker.getDirectoryPath();
    if (carpeta == null) return;
    state = state.copyWith(carpetaOut: carpeta);
  }

  /// Recarga la lista de `.md` de la carpeta de entrada (botón **Refrescar**).
  void cargarArchivos() {
    final archivos =
        ref.read(repositorioArchivosProvider).listarArchivosMd(state.carpetaIn);
    final rutas = archivos.map((a) => a.ruta).toSet();
    state = state.copyWith(
      archivos: archivos,
      seleccion: state.seleccion.where(rutas.contains).toSet(),
    );
  }

  // ----------------------------------------------------------- selección

  void alternarSeleccion(String ruta) {
    final seleccion = {...state.seleccion};
    if (!seleccion.add(ruta)) seleccion.remove(ruta);
    state = state.copyWith(seleccion: seleccion);
  }

  void seleccionarTodo() {
    state = state.copyWith(
      seleccion: state.archivos.map((a) => a.ruta).toSet(),
    );
  }

  void limpiarSeleccion() {
    state = state.copyWith(seleccion: const {});
  }

  // ----------------------------------------------------------- opciones

  void cambiarVoz(String voz) {
    state = state.copyWith(voz: voz);
  }

  void cambiarSteps(int steps) {
    state = state.copyWith(steps: steps.clamp(5, 12));
  }

  void cambiarSpeed(double speed) {
    state = state.copyWith(speed: speed.clamp(0.7, 2.0));
  }

  void cambiarLangVoz(String langVoz) {
    state = state.copyWith(langVoz: langVoz);
  }

  void alternarFormato(String formato) {
    final formatos = {...state.formatos};
    if (!formatos.add(formato)) formatos.remove(formato);
    state = state.copyWith(formatos: formatos);
  }

  // ------------------------------------------------------------- escuchar

  /// Sintetiza y reproduce una muestra de la voz e idioma seleccionados.
  Future<void> escuchar(AppLocalizations t) async {
    if (state.probandoVoz) return;
    state = state.copyWith(probandoVoz: true);
    final voz = state.voz;
    final lang = state.langVoz;
    try {
      _appendLog(t.log_muestra(voz, lang));
      await ref.read(motorTtsProvider).cambiarVoz(voz);
      final temp = await getTemporaryDirectory();
      final ruta = '${temp.path}${Platform.pathSeparator}'
          'supertonic_muestra_${voz}_$lang.wav';
      await ref.read(sintetizarMuestraProvider).generar(
            textoMuestraIdiomas[lang] ?? t.muestra_texto,
            lang: lang,
            ruta: ruta,
          );
      await ref.read(reproductorAudioProvider).reproducir(ruta);
      _appendLog(t.log_muestra_fin);
    } catch (_) {
      _appendLog(t.log_muestra_error);
    } finally {
      state = state.copyWith(probandoVoz: false);
    }
  }

  // ----------------------------------------------------------- procesar

  /// Cancela el procesamiento en curso (exporta lo generado hasta ahora).
  void cancelar(AppLocalizations t) {
    if (!state.ejecutando) return;
    state = state.copyWith(cancelar: true, estado: t.estado_cancelando);
    _appendLog(t.log_cancelar);
  }

  /// Inicia el procesamiento de los archivos seleccionados (o todos si no
  /// hay marcas), persistiendo antes las claves de §6.3.
  Future<void> procesar(AppLocalizations t) async {
    if (state.ejecutando) return;

    _guardarPreferencias();

    final formatos = state.formatos.toList()..sort();
    if (formatos.isEmpty) {
      state = state.copyWith(
        snackbar: MensajeSnackbar(t.snackbar_formato, esError: true),
        lineasLog: [...state.lineasLog, t.log_formato_no_ok],
      );
      return;
    }

    final archivos = state.archivos;
    final marcados = [
      for (final a in archivos)
        if (state.seleccion.contains(a.ruta)) a,
    ];
    final seleccion = marcados.isEmpty ? [...archivos] : marcados;
    if (seleccion.isEmpty) {
      state = state.copyWith(
        snackbar: MensajeSnackbar(t.snackbar_sin_md, esError: true),
        lineasLog: [...state.lineasLog, t.log_sin_md],
      );
      return;
    }

    final voz = state.voz;
    final steps = state.steps;
    final speed = state.speed;
    final lang = state.langVoz;
    final salida = state.carpetaOut;

    state = state.copyWith(
      ejecutando: true,
      cancelar: false,
      progresoActual: 0,
      progresoTotal: 0,
      estado: '',
      lineasLog: const [],
      snackbar: null,
    );
    _appendLog(t.log_inicio(seleccion.length, archivos.length));

    final inicio = DateTime.now();
    try {
      await ref.read(motorTtsProvider).cambiarVoz(voz);
      ref.read(repositorioArchivosProvider).crearCarpetasSiNoExisten([salida]);

      _appendLog('=' * 60);
      _appendLog(t.log_config_titulo);
      _appendLog(t.log_config_voz(voz, steps, '${speed.toStringAsFixed(2)}x'));
      _appendLog(t.log_config_lang(lang));
      _appendLog(t.log_config_formatos(
          formatos.map((f) => f.toUpperCase()).join(', ')));
      _appendLog(t.log_config_salida(salida));
      _appendLog('=' * 60);

      final useCase = ref.read(procesarArchivoProvider);
      final totalArchivos = seleccion.length;
      var exitos = 0;
      var errores = 0;
      for (var i = 0; i < totalArchivos; i++) {
        final archivo = seleccion[i];
        if (state.cancelar) break;
        state = state.copyWith(
          estado: t.estado_archivo(i + 1, totalArchivos, archivo.nombre),
          progresoActual: 0,
          progresoTotal: 0,
        );
        _appendLog(t.log_archivo(i + 1, totalArchivos, archivo.nombre));
        try {
          await useCase.procesar(
            archivo,
            '$salida${Platform.pathSeparator}${archivo.titulo}',
            steps: steps,
            speed: speed,
            formatos: formatos,
            lang: lang,
            onProgreso: (actual, total) => _onProgreso(t, actual, total),
            debeDetenerse: () => state.cancelar,
          );
          _appendLog(t.log_archivo_fin(i + 1, totalArchivos));
          exitos++;
        } catch (exc) {
          errores++;
          _appendLog('Error en ${archivo.nombre}: $exc');
        }
      }

      final elapsed = DateTime.now().difference(inicio).inSeconds.toDouble();
      final textoElapsed = _formatearTiempo(t, elapsed);
      final finalizadoOk = !state.cancelar;
      state = state.copyWith(ejecutando: false);

      if (finalizadoOk && errores == 0) {
        state = state.copyWith(
          progresoActual: 1,
          progresoTotal: 1,
          estado: t.estado_listo_n(exitos, textoElapsed),
          snackbar: MensajeSnackbar(t.snackbar_procesado(exitos, textoElapsed)),
        );
        _appendLog('=' * 60);
        _appendLog(t.log_completado(exitos, textoElapsed));
        _appendLog('=' * 60);
      } else if (finalizadoOk && errores > 0) {
        state = state.copyWith(
          estado: t.estado_con_errores(exitos, totalArchivos, errores),
          snackbar: MensajeSnackbar(
            t.snackbar_con_errores(exitos, errores, textoElapsed),
            esError: true,
          ),
        );
        _appendLog(t.log_con_errores(errores, totalArchivos));
      } else {
        state = state.copyWith(
          estado: t.estado_cancelado,
          snackbar: MensajeSnackbar(t.snackbar_exportado),
        );
        _appendLog(t.log_cancelado(textoElapsed));
      }
    } catch (exc) {
      state = state.copyWith(ejecutando: false, estado: t.estado_error);
      state = state.copyWith(
        snackbar: MensajeSnackbar('$exc', esError: true),
        lineasLog: [...state.lineasLog, t.log_error('$exc')],
      );
    }
  }

  // ------------------------------------------------------------- helpers

  void _guardarPreferencias() {
    final prefs = {
      ...ref.read(repositorioPreferenciasProvider).cargar(),
      'voz': state.voz,
      'steps': state.steps,
      'speed': state.speed,
      'lang_voz': state.langVoz,
      'formatos': [...state.formatos]..sort(),
      'carpeta_in': state.carpetaIn,
      'carpeta_out': state.carpetaOut,
    };
    ref.read(repositorioPreferenciasProvider).guardar(prefs);
  }

  void _onProgreso(AppLocalizations t, int actual, int total) {
    final paso = math.max(1, total ~/ 20);
    state = state.copyWith(
      progresoActual: actual,
      progresoTotal: total,
      estado: t.estado_segmentos(actual, total),
    );
    if (actual % paso == 0 || actual == total) {
      _appendLog(t.log_segmento(actual, total));
    }
  }

  /// Formato de tiempo de §6.1: "{total} s", "{min} min {seg} s", "{horas} h
  /// {min} min".
  String _formatearTiempo(AppLocalizations t, double segundos) {
    final total = segundos.floor();
    if (total < 60) return t.tiempo_seg(total);
    final minutos = total ~/ 60;
    final seg = total % 60;
    if (minutos < 60) return t.tiempo_min_seg(minutos, seg);
    final horas = minutos ~/ 60;
    final min = minutos % 60;
    return t.tiempo_hora_min(horas, min);
  }

  /// Agrega una línea al registro, truncándolo a 2500 líneas (paridad).
  void _appendLog(String texto) {
    final lineas = [...state.lineasLog, texto];
    if (lineas.length > 3000) {
      state = state.copyWith(lineasLog: lineas.sublist(lineas.length - 2500));
    } else {
      state = state.copyWith(lineasLog: lineas);
    }
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeEstado>(HomeController.new);
