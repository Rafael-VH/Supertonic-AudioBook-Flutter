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

/// Envuelve el [ResultadoProceso] con métricas adicionales del procesamiento.
///
/// Agrega cantidad de segmentos y duración total del audio generado,
/// información que el caller puede usar para logs, estimaciones y UI.
class ProcesarResultado {
  const ProcesarResultado({
    required this.estado,
    required this.segmentos,
    required this.duracionAudioSeg,
    required this.caracteres,
    this.tempPath,
  });

  /// Estado semántico del procesamiento.
  final ResultadoProceso estado;

  /// Cantidad de segmentos de texto procesados.
  final int segmentos;

  /// Duración total del audio generado en segundos.
  final double duracionAudioSeg;

  /// Cantidad de caracteres del texto plano procesado.
  final int caracteres;

  /// Ruta al WAV temporal en `_temp/`, null si el procesamiento no fue exitoso.
  final String? tempPath;
}

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

  /// Convierte [archivo] en un WAV temporal en `_temp/` bajo [rutaBase].
  ///
  /// Devuelve [ResultadoProceso.ok] con `tempPath` apuntando al WAV generado;
  /// [ResultadoProceso.error] si el archivo no se pudo leer (sin lanzar, el
  /// resultado comunica el fallo) y [ResultadoProceso.omitido] si tras limpiar
  /// no quedó contenido o el motor no generó audio. Las demás fallas (motor,
  /// exportador) se lanzan y el caller las cuenta.
  ///
  /// El WAV resultante queda en `_temp/` y el caller es responsable de su
  /// lifecycle (guardar, eliminar, limpiar).
  Future<ProcesarResultado> procesar(
    Archivo archivo,
    String rutaBase, {
    required int steps,
    required double speed,
    required List<String> formatos,
    String lang = defaultLang,
    void Function(int procesados, int total)? onProgreso,
    bool Function()? debeDetenerse,
  }) async {
    _logger.i('=' * 40);
    _logger.i('  Procesando: ${archivo.nombre}');
    _logger.i('=' * 40);

    // --- Leer y limpiar ---
    String textoPlano;
    try {
      textoPlano = limpiarMarkdown(_archivos.leerArchivo(archivo.ruta));
    } catch (exc) {
      _logger.e("No se pudo leer '${archivo.ruta}': $exc");
      return const ProcesarResultado(estado: ResultadoProceso.error, segmentos: 0, duracionAudioSeg: 0, caracteres: 0);
    }

    if (textoPlano.trim().isEmpty) {
      _logger.i('El archivo está vacío después de limpiar. Se omite.');
      return const ProcesarResultado(estado: ResultadoProceso.omitido, segmentos: 0, duracionAudioSeg: 0, caracteres: 0);
    }

    // --- Segmentar ---
    final segmentos = segmentarTexto(textoPlano);
    final total = segmentos.length;
    _logger.i('  → $total segmento(s) para procesar.');

    // El WAV de trabajo es SIEMPRE un temporal: nada se escribe sobre la
    // ruta final hasta que la corrida terminó con éxito.
    final dirSalida = _fileSystem.parentOf(rutaBase);
    _fileSystem.createDirectory(dirSalida);
    // Subdirectorio _temp/ para WIPs: el caller gestiona su lifecycle.
    final tempDir = '$dirSalida${_fileSystem.pathSeparator}_temp';
    _fileSystem.createDirectory(tempDir);
    final temporales = <String>[];
    final rutaWavTrabajo = _nuevoTemporal(tempDir, 'wav', temporales);
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
        return const ProcesarResultado(estado: ResultadoProceso.omitido, segmentos: 0, duracionAudioSeg: 0, caracteres: 0);
      }

      // Formatos normalizados sin duplicados.
      final formatosUnicos = <String>[];
      for (final f in formatos) {
        if (!formatosUnicos.contains(f)) formatosUnicos.add(f);
      }

      // --- Exportar ---
      _logger.i('Exportando audio...');
      if (parcialEscrito) {
        await _exportador.wavAppend(fragmentos, rutaWavTrabajo);
      } else {
        await _exportador.escribirAudio(fragmentos, rutaWavTrabajo, 'wav');
      }

      // Convertir WAV a formatos solicitados → guardados en _temp/.
      for (final formato in formatosUnicos) {
        if (formato == 'wav') continue; // WAV ya está en _temp/
        try {
          final stem = _fileSystem.fileName(rutaBase);
          final ts = DateTime.now().microsecondsSinceEpoch;
          final destPath =
              '$tempDir${_fileSystem.pathSeparator}${stem}_$ts.$formato';
          await _exportador.convertirDesdeWav(rutaWavTrabajo, destPath, formato);
        } catch (exc) {
          _logger.e("Fallo al exportar formato '$formato': $exc");
        }
      }
    } finally {
      // No eliminar rutaWavTrabajo — el caller gestiona su lifecycle.
      for (final temporal in temporales) {
        if (temporal != rutaWavTrabajo) {
          _fileSystem.deleteFile(temporal);
        }
      }
    }

    final duracionTotal = await _exportador.duracionAudio(rutaWavTrabajo);
    return ProcesarResultado(
      estado: ResultadoProceso.ok,
      segmentos: segmentos.length,
      duracionAudioSeg: duracionTotal,
      caracteres: textoPlano.length,
      tempPath: rutaWavTrabajo,
    );
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
