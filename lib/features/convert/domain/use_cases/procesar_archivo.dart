import 'dart:typed_data';

import 'package:supertonic_audiobook/shared/domain/constants/producto.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/file_system.dart';
import 'package:supertonic_audiobook/features/convert/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/domain_logger.dart';
import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/limpiar_markdown.dart';
import 'package:supertonic_audiobook/features/convert/domain/use_cases/segmentar_texto.dart';

/// Resultado de convertir un archivo con [ProcesarArchivo.procesar].
///
/// Un archivo que no se pudo leer es un [error] (el caller debe reportarlo);
/// uno que queda sin contenido tras limpiar se [omitido] (no cuenta como
/// éxito ni como error). Las excepciones de síntesis/exportación siguen
/// propagándose: el caller las cuenta como errores.
enum ResultadoProceso { ok, omitido, error }

/// Orquesta la conversión de un archivo Markdown a audios.
///
/// Paridad con `app/domain/use_cases/procesar_archivo.py`: depende SOLO de
/// contratos de dominio y funciones puras; los valores técnicos (silencio
/// entre segmentos, margen de memoria) se inyectan desde la composición.
class ProcesarArchivo {
  ProcesarArchivo({
    required this._motor,
    required this._archivos,
    required this._exportador,
    required this._fileSystem,
    required this._silencioMuestras,
    required this._memoriaSafeMarginBytes,
    required this._topeMovilBytes,
    required this._logger,
    this._esMovil = false,
  });

  final MotorTts _motor;
  final RepositorioArchivos _archivos;
  final ExportadorAudio _exportador;
  final FileSystemContract _fileSystem;
  final int _silencioMuestras;
  final int _memoriaSafeMarginBytes;
  final DomainLogger _logger;

  /// Presupuesto de RAM para retener fragmentos en móvil (inyectado desde la
  /// composición; el dominio no conoce valores de `data/`).
  final int _topeMovilBytes;

  /// Verdadero en Android/iOS (decidido en la composición, no con `dart:io`):
  /// el heap disponible es mucho menor que el de desktop y acumular cientos
  /// de MiB de Float32 provoca OOM.
  final bool _esMovil;

  /// Presupuesto efectivo de RAM para retener fragmentos antes de volcar a
  /// disco. En móvil se usa [topeMovil] (heap chico → OOM con 500 MiB);
  /// en desktop se mantiene [memoriaSafeMarginBytes]. Pura: se testea sin
  /// device.
  static int presupuestoMemoria({
    required int memoriaSafeMarginBytes,
    required bool esMovil,
    required int topeMovil,
  }) {
    if (!esMovil) return memoriaSafeMarginBytes;
    return memoriaSafeMarginBytes < topeMovil
        ? memoriaSafeMarginBytes
        : topeMovil;
  }

  /// Convierte [archivo] en audios en los formatos pedidos.
  ///
  /// Devuelve [ResultadoProceso.ok] si se publicó al menos una salida;
  /// [ResultadoProceso.error] si el archivo no se pudo leer (sin lanzar, el
  /// resultado comunica el fallo) y [ResultadoProceso.omitido] si tras
  /// limpiar no quedó contenido o el motor no generó audio. Las demás fallas
  /// (motor, exportador, publicación) se lanzan y el caller las cuenta.
  ///
  /// Cada salida se publica por separado y de forma atómica (renombrado de
  /// archivo temporal), solo después de generarla por completo. Si la corrida
  /// se cancela o falla durante la síntesis, el output previo de cada formato
  /// queda intacto: al cancelar solo se publican salidas cuyo destino no
  /// existía previamente, para no pisar audio completo con audio truncado.
  /// En la fase de publicación el WAV va último: si falla un formato no-WAV,
  /// el WAV previo no se reemplaza.
  Future<ResultadoProceso> procesar(
    Archivo archivo,
    String rutaBase, {
    required int steps,
    required double speed,
    required List<String> formatos,
    String lang = defaultLang,
    void Function(int procesados, int total)? onProgreso,
    bool Function()? debeDetenerse,
  }) async {
    _logger.i('=' * 50);
    _logger.i('  Procesando: ${archivo.nombre}');
    _logger.i('=' * 50);

    // --- Leer y limpiar ---
    String textoPlano;
    try {
      textoPlano = limpiarMarkdown(_archivos.leerArchivo(archivo.ruta));
    } catch (exc) {
      _logger.e("No se pudo leer '${archivo.ruta}': $exc");
      return ResultadoProceso.error;
    }

    if (textoPlano.trim().isEmpty) {
      _logger.i('El archivo está vacío después de limpiar. Se omite.');
      return ResultadoProceso.omitido;
    }

    // --- Segmentar ---
    final segmentos = segmentarTexto(textoPlano);
    final total = segmentos.length;
    _logger.i('  → $total segmento(s) para procesar.');

    // Formatos normalizados sin duplicados: un repetido haría fallar la
    // publicación del mismo temporal dos veces.
    final formatosUnicos = <String>[];
    for (final f in formatos) {
      if (!formatosUnicos.contains(f)) formatosUnicos.add(f);
    }

    // El WAV de trabajo es SIEMPRE un temporal: nada se escribe sobre la
    // ruta final hasta que la corrida terminó con éxito.
    final dirSalida = _fileSystem.parentOf(rutaBase);
    _fileSystem.createDirectory(dirSalida);
    final temporales = <String>[];
    final rutaWavTrabajo = _nuevoTemporal(dirSalida, 'wav', temporales);
    temporales.add(rutaWavTrabajo);

    // --- Sintetizar incrementalmente ---
    _logger.i('Generando voz sintética...');
    final presupuesto = presupuestoMemoria(
      memoriaSafeMarginBytes: _memoriaSafeMarginBytes,
      esMovil: _esMovil,
      topeMovil: _topeMovilBytes,
    );
    final fragmentos = <Float32List>[];
    var memoriaAcumulada = 0;
    var parcialEscrito = false;
    var cancelado = false;

    try {
      var procesados = 0;
      for (final texto in segmentos) {
        procesados++;
        if (debeDetenerse != null && debeDetenerse()) {
          cancelado = true;
          break;
        }

        final wav = await _motor.sintetizar(texto, steps: steps, speed: speed, lang: lang);
        if (onProgreso != null) onProgreso(procesados, total);
        if (wav.isEmpty) continue;

        fragmentos.add(wav);
        memoriaAcumulada += wav.length * 4;
        fragmentos.add(Float32List(_silencioMuestras));
        memoriaAcumulada += _silencioMuestras * 4;

        // Si acumulamos mucha RAM, volcamos a disco.
        if (memoriaAcumulada > presupuesto) {
          _logger.i('Volcando a disco por límite de memoria...');
          await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
          fragmentos.clear();
          memoriaAcumulada = 0;
          parcialEscrito = true;
        }
      }

      if (cancelado) {
        _logger.i('Cancelado por el usuario. Exportando lo generado hasta ahora...');
      }

      if (fragmentos.isEmpty && !parcialEscrito) {
        _logger.i('No se generó ningún fragmento de audio.');
        return ResultadoProceso.omitido;
      }

      // --- Exportar ---
      _logger.i('Exportando audio...');
      // Fase 1: generar todo a archivos temporales. Un fallo de conversión
      // en un formato no aborta los demás: se loguea y se continua. Solo los
      // formatos que convirtieron exitosamente se publican.
      final salidas = <(String, String)>[];
      if (parcialEscrito) {
        await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
        for (final formato in formatosUnicos) {
          try {
            if (formato == 'wav') {
              salidas.add((rutaWavTrabajo, '$rutaBase.wav'));
            } else {
              final temporal = _nuevoTemporal(dirSalida, formato, temporales);
              await _exportador.convertirDesdeWav(rutaWavTrabajo, temporal, formato);
              salidas.add((temporal, '$rutaBase.$formato'));
            }
          } catch (exc) {
            _logger.e("Fallo al exportar formato '$formato': $exc");
          }
        }
      } else {
        for (final formato in formatosUnicos) {
          try {
            final temporal = _nuevoTemporal(dirSalida, formato, temporales);
            await _exportador.escribirAudio(fragmentos, temporal, formato);
            salidas.add((temporal, '$rutaBase.$formato'));
          } catch (exc) {
            _logger.e("Fallo al exportar formato '$formato': $exc");
          }
        }
      }

      // Fase 2: publicar. El WAV se publica al final: si un formato falla,
      // no queda un WAV nuevo con el resto de los formatos viejos. Al
      // cancelar, un destino que ya existía (de una corrida anterior) se
      // conserva: nunca se pisa audio completo con el truncado de la corrida
      // cancelada (semántica prometida en el docstring).
      for (final par in ordenPublicacion(salidas)) {
        if (cancelado && _fileSystem.fileExists(par.$2)) {
          _logger.i("Cancelado: se conserva el output previo '${par.$2}'.");
          continue;
        }
        _publicar(par.$1, par.$2, temporales);
      }
    } finally {
      for (final temporal in temporales) {
        _fileSystem.deleteFile(temporal);
      }
    }

    for (final formato in formatosUnicos) {
      final ruta = '$rutaBase.$formato';
      final duracion = await _exportador.duracionAudio(ruta);
      _logger.i('  + ${_fileSystem.fileName(ruta)} (${formato.toUpperCase()}): ${duracion.toStringAsFixed(1)} s');
    }
    return ResultadoProceso.ok;
  }

  /// Publica [origen] como [destino] solo en éxito.
  void _publicar(String origen, String destino, List<String> temporales) {
    final ok = _fileSystem.renameFile(origen, destino);
    if (!ok) {
      _logger.w("El archivo '$destino' está en uso por otra aplicación; no se actualizó.");
    }
    temporales.remove(origen);
  }

  /// Ordena las salidas para publicar: los no-WAV primero, el WAV al final.
  static List<(String, String)> ordenPublicacion(List<(String, String)> salidas) {
    final copia = [...salidas];
    copia.sort((a, b) {
      final aWav = a.$2.toLowerCase().endsWith('.wav');
      final bWav = b.$2.toLowerCase().endsWith('.wav');
      if (aWav == bWav) return 0;
      return aWav ? 1 : -1;
    });
    return copia;
  }

  /// Crea un archivo temporal de salida y lo registra para limpieza.
  String _nuevoTemporal(String carpeta, String sufijo, List<String> temporales) {
    final path =
        '$carpeta${_fileSystem.pathSeparator}.tmp_${DateTime.now().microsecondsSinceEpoch}_'
        '${temporales.length}_$sufijo';
    _fileSystem.createFile(path);
    return path;
  }
}
