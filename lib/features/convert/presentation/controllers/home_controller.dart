import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/shared/domain/constants/producto.dart';
import 'package:supertonic_audiobook/features/convert/domain/entities/selection_mode.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/shared/domain/entities/voice_config.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/procesar_archivo.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/use_cases/estimar_tiempo.dart';
import 'package:supertonic_audiobook/features/convert/presentation/constants/muestra_voz.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/selection_manager.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/preferences_persistence.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/voice_preview_service.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Mensaje de snackbar emitido por el controlador para que la pantalla lo
/// muestre (y lo limpie con `ref.listen`).
class MensajeSnackbar {
  const MensajeSnackbar(this.texto, {this.esError = false});

  final String texto;
  final bool esError;
}

/// Estado de la pantalla Home (paridad con `gui.py`).
class HomeEstado {
  const HomeEstado({
    required this.carpetaIn,
    required this.carpetaOut,
    required this.archivos,
    required this.seleccion,
    required this.voiceConfig,
    required this.formatos,
    required this.ejecutando,
    required this.probandoVoz,
    required this.cancelar,
    required this.progresoActual,
    required this.progresoTotal,
    required this.estado,
    required this.lineasLog,
    required this.snackbar,
    this.modoSeleccion = SelectionMode.carpeta,
  });

  final String carpetaIn;
  final String carpetaOut;
  final List<Archivo> archivos;

  /// Rutas marcadas en la lista. Vacío = "todos" (behavior de la ayuda).
  final Set<String> seleccion;

  final VoiceConfig voiceConfig;
  final Set<String> formatos;

  final bool ejecutando;
  final bool probandoVoz;
  final bool cancelar;

  final int progresoActual;
  final int progresoTotal;

  /// Línea de estado (vacío = "Listo." del i18n).
  final String estado;

  /// Registro (log), truncado a 2500 líneas.
  final List<String> lineasLog;

  final MensajeSnackbar? snackbar;

  /// Modo de selección de entrada: carpeta o archivos individuales.
  final SelectionMode modoSeleccion;

  HomeEstado copyWith({
    String? carpetaIn,
    String? carpetaOut,
    List<Archivo>? archivos,
    Set<String>? seleccion,
    VoiceConfig? voiceConfig,
    Set<String>? formatos,
    bool? ejecutando,
    bool? probandoVoz,
    bool? cancelar,
    int? progresoActual,
    int? progresoTotal,
    String? estado,
    List<String>? lineasLog,
    MensajeSnackbar? snackbar,
    bool clearSnackbar = false,
    SelectionMode? modoSeleccion,
  }) {
    return HomeEstado(
      carpetaIn: carpetaIn ?? this.carpetaIn,
      carpetaOut: carpetaOut ?? this.carpetaOut,
      archivos: archivos ?? this.archivos,
      seleccion: seleccion ?? this.seleccion,
      voiceConfig: voiceConfig ?? this.voiceConfig,
      formatos: formatos ?? this.formatos,
      ejecutando: ejecutando ?? this.ejecutando,
      probandoVoz: probandoVoz ?? this.probandoVoz,
      cancelar: cancelar ?? this.cancelar,
      progresoActual: progresoActual ?? this.progresoActual,
      progresoTotal: progresoTotal ?? this.progresoTotal,
      estado: estado ?? this.estado,
      lineasLog: lineasLog ?? this.lineasLog,
      snackbar: clearSnackbar ? null : (snackbar ?? this.snackbar),
      modoSeleccion: modoSeleccion ?? this.modoSeleccion,
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
  late final SelectionManager _selectionManager;
  late final PreferencesPersistence _persistence;

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
        ((prefs['formatos'] as List?)?.cast<String>() ?? ['mp3'])
            .toSet();

    final archivos =
        ref.read(repositorioArchivosProvider).listarArchivosMd(carpetaIn);

    _selectionManager = SelectionManager();
    _persistence = PreferencesPersistence(
      repositorio: ref.read(repositorioPreferenciasProvider),
    );

    return HomeEstado(
      carpetaIn: carpetaIn,
      carpetaOut: carpetaOut,
      archivos: archivos,
      seleccion: const {},
      voiceConfig: VoiceConfig(
        voz: voz,
        steps: steps,
        speed: speed,
        langVoz: langVoz,
      ),
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
    final carpeta = await _persistence.pickCarpetaIn();
    if (carpeta == null) return;
    state = state.copyWith(carpetaIn: carpeta);
    cargarArchivos();
  }

  Future<void> examinarCarpetaOut() async {
    final carpeta = await _persistence.pickCarpetaOut();
    if (carpeta == null) return;
    state = state.copyWith(carpetaOut: carpeta);
  }

  /// Setea la carpeta de entrada y cambia a modo carpeta (usado desde HomeScreen).
  void setCarpetaIn(String carpeta) {
    state = state.copyWith(
      carpetaIn: carpeta,
      modoSeleccion: SelectionMode.carpeta,
    );
    cargarArchivos();
  }

  /// Establece el modo de selección y carga los archivos correspondientes.
  /// En modo `archivos`, [archivosExternos] son las rutas pre-seleccionadas.
  void setModo(SelectionMode modo, {List<Archivo>? archivosExternos}) {
    if (modo == SelectionMode.archivos && archivosExternos != null) {
      state = state.copyWith(
        modoSeleccion: modo,
        archivos: archivosExternos,
        seleccion: {},
        carpetaIn: '',
      );
    } else {
      state = state.copyWith(modoSeleccion: modo);
      if (modo == SelectionMode.carpeta) {
        cargarArchivos();
      }
    }
  }

  /// Recarga la lista de `.md` de la carpeta de entrada (botón **Refrescar**).
  void cargarArchivos() {
    final archivos =
        ref.read(repositorioArchivosProvider).listarArchivosMd(state.carpetaIn);
    _selectionManager.filtrarSeleccion(archivos);
    state = state.copyWith(
      archivos: archivos,
      seleccion: _selectionManager.seleccion,
    );
  }

  /// Reemplaza la lista con archivos elegidos por el buscador de archivos
  /// (pantalla de selección), preservando las marcas que aún existen y
  /// limpiando el estado de una corrida anterior. Si hay procesamiento o una
  /// muestra de voz en vuelo el reemplazo (y el borrado de
  /// [quitarArchivoExterno], que pasa por acá) se ignora: el reset
  /// destructivo dejaría inerte una cancelación en vuelo y habilitaría una
  /// segunda corrida concurrente sobre el mismo motor TTS.
  void cargarArchivosExternos(List<Archivo> archivos) {
    if (state.ejecutando || state.probandoVoz) return;
    _selectionManager.mergeArchivosExternos(archivos);
    state = state.copyWith(
      archivos: archivos,
      seleccion: _selectionManager.seleccion,
      ejecutando: false,
      cancelar: false,
      progresoActual: 0,
      progresoTotal: 0,
      estado: '',
      lineasLog: const [],
      clearSnackbar: true,
    );
  }

  /// Agrega archivos elegidos por el buscador a la selección existente
  /// (botón **Agregar**), fusionando sin duplicados por ruta y preservando
  /// las marcas previas. No toca el estado de una corrida en curso: si hay
  /// procesamiento activo el tap se ignora (el motor TTS no soporta
  /// concurrencia y no debe limpiarse una cancelación en vuelo ni el log).
  void agregarArchivosExternos(List<Archivo> archivos) {
    if (state.ejecutando) return;
    final porRuta = <String, Archivo>{
      for (final a in state.archivos) a.ruta: a,
      for (final a in archivos) a.ruta: a,
    };
    final fusionados = porRuta.values.toList();
    _selectionManager.mergeArchivosExternos(fusionados);
    state = state.copyWith(
      archivos: fusionados,
      seleccion: _selectionManager.seleccion,
    );
  }

  /// Quita un archivo externo de la lista (botón quitar de la selección).
  void quitarArchivoExterno(String ruta) {
    cargarArchivosExternos(
      [...state.archivos.where((a) => a.ruta != ruta)],
    );
  }

  // ----------------------------------------------------------- selección

  void alternarSeleccion(String ruta) {
    _selectionManager.alternarSeleccion(ruta);
    state = state.copyWith(seleccion: _selectionManager.seleccion);
  }

  void seleccionarTodo() {
    _selectionManager.seleccionarTodo(state.archivos);
    state = state.copyWith(seleccion: _selectionManager.seleccion);
  }

  void limpiarSeleccion() {
    _selectionManager.limpiarSeleccion();
    state = state.copyWith(seleccion: _selectionManager.seleccion);
  }

  // ----------------------------------------------------------- opciones

  void cambiarVoz(String voz) {
    state = state.copyWith(
      voiceConfig: state.voiceConfig.copyWith(voz: voz),
    );
  }

  void cambiarSteps(int steps) {
    state = state.copyWith(
      voiceConfig: state.voiceConfig.copyWith(steps: steps.clamp(5, 12)),
    );
  }

  void cambiarSpeed(double speed) {
    state = state.copyWith(
      voiceConfig: state.voiceConfig.copyWith(speed: speed.clamp(0.7, 2.0)),
    );
  }

  void cambiarLangVoz(String langVoz) {
    state = state.copyWith(
      voiceConfig: state.voiceConfig.copyWith(langVoz: langVoz),
    );
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
    final voz = state.voiceConfig.voz;
    final lang = state.voiceConfig.langVoz;
    try {
      _appendLog(t.log_muestra(voz, lang));
      final service = VoicePreviewService(
        motorTts: ref.read(motorTtsProvider),
        sintetizarMuestra: ref.read(sintetizarMuestraProvider),
        reproductorAudio: ref.read(reproductorAudioProvider),
      );
      await service.reproducirMuestra(
        voz: voz,
        lang: lang,
        textoMuestra: textoMuestraIdiomas[lang] ?? t.muestra_texto,
      );
      _appendLog(t.log_muestra_fin);
    } catch (exc) {
      // SintetizarMuestra relanza la causa real: se reporta en el log para
      // que el fallo no quede mudo (p. ej. motor no disponible, ruta ilegible).
      _appendLog('${t.log_muestra_error}: $exc');
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
  /// hay marcas), persistiendo antes las claves de §6.3. Se bloquea mientras
  /// hay una corrida en curso o una muestra de voz reproduciéndose: el motor
  /// TTS no soporta síntesis concurrentes.
  Future<void> procesar(AppLocalizations t) async {
    if (state.ejecutando || state.probandoVoz) return;

    _persistence.guardarPreferencias(
      voiceConfig: state.voiceConfig,
      formatos: state.formatos,
      carpetaIn: state.carpetaIn,
      carpetaOut: state.carpetaOut,
    );

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

    final voz = state.voiceConfig.voz;
    final steps = state.voiceConfig.steps;
    final speed = state.voiceConfig.speed;
    final lang = state.voiceConfig.langVoz;
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

      _appendLog('=' * 40);
      _appendLog(t.log_config_titulo);
      _appendLog(t.log_config_voz(voz, steps, '${speed.toStringAsFixed(2)}x'));
      _appendLog(t.log_config_lang(lang));
      _appendLog(t.log_config_formatos(
          formatos.map((f) => f.toUpperCase()).join(', ')));
      _appendLog(t.log_config_salida(salida));
      _appendLog('=' * 40);

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
          final resultado = await useCase.procesar(
            archivo,
            '$salida${Platform.pathSeparator}${archivo.titulo}',
            steps: steps,
            speed: speed,
            formatos: formatos,
            lang: lang,
            onProgreso: (actual, total) => _onProgreso(t, actual, total),
            debeDetenerse: () => state.cancelar,
          );
          switch (resultado.estado) {
            case ResultadoProceso.ok:
              _appendLog(t.log_archivo_fin(i + 1, totalArchivos));
              _appendLog('  Segmentos: ${resultado.segmentos}, Audio: ${resultado.duracionAudioSeg.toStringAsFixed(1)}s');
              exitos++;
              _guardarConversionEnHistorial(
                nombreArchivo: archivo.nombre,
                caracteres: resultado.caracteres,
                segmentos: resultado.segmentos,
                duracionAudioSeg: resultado.duracionAudioSeg,
              );
            case ResultadoProceso.omitido:
              _appendLog(
                  t.log_archivo_omitido(i + 1, totalArchivos, archivo.nombre));
            case ResultadoProceso.error:
              errores++;
              _appendLog(
                  t.log_archivo_error(i + 1, totalArchivos, archivo.nombre));
          }
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
        _appendLog('=' * 40);
        _appendLog(t.log_completado(exitos, textoElapsed));
        _mostrarEstimacion(t, seleccion);
        _appendLog('=' * 40);
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

  /// Muestra la estimación de tiempo si hay un benchmark guardado.
  void _mostrarEstimacion(AppLocalizations t, List<Archivo> archivos) {
    final prefs = ref.read(repositorioBenchmarkProvider).cargar();
    final benchmarkData = prefs['benchmark_results'];
    if (benchmarkData is! Map<String, Object?>) return;

    final benchmark = BenchmarkResult.fromMap(benchmarkData);
    if (benchmark.tamanios.isEmpty) return;

    // Calcular total de caracteres aproximados de los archivos seleccionados.
    var totalChars = 0;
    for (final archivo in archivos) {
      totalChars += archivo.nombre.length * 50; // estimación rough
    }

    final estimated = estimarTiempo(benchmark: benchmark, textoChars: totalChars);
    if (estimated != null) {
      _appendLog('  Estimado (benchmark): ${_formatearTiempo(t, estimated)}');
    }
  }

  /// Guarda una entrada en el historial de conversiones (prefs).
  ///
  /// Prepende la entrada más reciente y mantiene un máximo de 100 entradas.
  void _guardarConversionEnHistorial({
    required String nombreArchivo,
    required int caracteres,
    required int segmentos,
    required double duracionAudioSeg,
  }) {
    final prefsRepo = ref.read(repositorioHistorialProvider);
    final datos = prefsRepo.cargar();
    final raw = datos['conversion_history'];
    final historial = <Map<String, Object?>>[];
    if (raw is List) {
      historial.addAll(raw.whereType<Map>().cast<Map<String, Object?>>());
    }
    historial.insert(0, ConversionEntry(
      nombreArchivo: nombreArchivo,
      caracteres: caracteres,
      segmentos: segmentos,
      duracionAudioSeg: duracionAudioSeg,
      fecha: DateTime.now(),
    ).toMap());
    // Cap at 100 entries.
    if (historial.length > 100) {
      historial.removeRange(100, historial.length);
    }
    datos['conversion_history'] = historial;
    prefsRepo.guardar(datos);
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeEstado>(HomeController.new);
