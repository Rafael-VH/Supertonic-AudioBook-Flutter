import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';

import 'package:supertonic_audiobook/domain/contracts/exportador_audio.dart';
import 'package:supertonic_audiobook/domain/contracts/modelo_gestor.dart';
import 'package:supertonic_audiobook/domain/contracts/motor_tts.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_preferencias.dart';
import 'package:supertonic_audiobook/domain/contracts/reproductor_audio.dart';
import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/domain/use_cases/procesar_archivo.dart';

/// Preferencias en memoria para los tests (sin disco).
class PreferenciasMemoria implements RepositorioPreferencias {
  PreferenciasMemoria([Map<String, Object>? inicial])
      : _datos = {...?inicial};

  final Map<String, Object> _datos;

  @override
  Map<String, Object> cargar() => Map.of(_datos);

  @override
  void guardar(Map<String, Object> preferencias) {
    _datos
      ..clear()
      ..addAll(preferencias);
  }

  Map<String, Object> get datos => Map.unmodifiable(_datos);
}

/// Repositorio de archivos falso con una lista fija de `.md`.
class RepositorioArchivosFake implements RepositorioArchivos {
  RepositorioArchivosFake(this.archivos, {this.carpetasCreadas});

  final List<Archivo> archivos;
  final List<String>? carpetasCreadas;

  int listados = 0;

  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {
    carpetasCreadas?.addAll(carpetas);
  }

  @override
  List<Archivo> listarArchivosMd(String carpeta) {
    listados++;
    return archivos;
  }

  @override
  String leerArchivo(String ruta) => '';
}

/// Motor falso que registra las voces pedidas.
class MotorFake implements MotorTts {
  final List<String> vocesPedidas = [];

  /// Si se define, `cambiarVoz` queda esperando hasta completarlo (para
  /// simular un procesamiento en curso sin tocar el filesystem).
  Completer<void>? esperaVoz;

  @override
  Future<void> cambiarVoz(String voz) async {
    vocesPedidas.add(voz);
    if (esperaVoz != null) await esperaVoz!.future;
  }

  @override
  Future<Float32List> sintetizar(
    String texto, {
    required int steps,
    required double speed,
    String lang = 'es',
  }) async {
    return Float32List(4410);
  }
}

/// Exportador falso que registra lo escrito.
class ExportadorFake implements ExportadorAudio {
  final List<String> escritos = [];

  @override
  Future<void> escribirAudio(
      List<Float32List> fragmentos, String ruta, String formato) async {
    escritos.add('$ruta.$formato');
  }

  @override
  Future<void> convertirDesdeWav(
      String rutaWav, String rutaDestino, String formato) async {}

  @override
  Future<double> duracionAudio(String ruta) async => 1.0;

  @override
  Future<void> wavAppend(List<Float32List> fragmentos, String ruta) async {}
}

/// Reproductor falso.
class ReproductorFake implements ReproductorAudio {
  final List<String> rutas = [];

  @override
  Future<void> reproducir(String ruta) async {
    rutas.add(ruta);
  }
}

/// Gestor del modelo falso.
///
/// Emite 10 MB de progreso en bloques de 1 MB. Si se define [espera], la
/// descarga queda bloqueada hasta completarlo (para probar progreso y
/// cancelación). [fallar] lanza un error apenas inicia.
class ModeloGestorFake implements ModeloGestor {
  ModeloGestorFake({this.disponible = false, this.fallar = false});

  bool disponible;
  final bool fallar;

  int descargas = 0;
  int cancelaciones = 0;
  Completer<void>? espera;

  /// Si se define, `verificarDisponible` espera antes de resolver (para
  /// simular la carrera con una descarga iniciada mientras se verifica).
  Completer<void>? verificacionLenta;

  static const int _mb = 1 << 20;

  @override
  Future<bool> verificarDisponible() async {
    if (verificacionLenta != null) await verificacionLenta!.future;
    return disponible;
  }

  @override
  Future<Directory> asegurarModelo({
    void Function(int bytes, int total, String archivo)? onProgreso,
  }) async {
    descargas++;
    if (fallar) throw Exception('fallo simulado');
    const total = 10 * _mb;
    onProgreso?.call(1 * _mb, total, 'onnx/vocoder.onnx');
    if (espera != null) await espera!.future;
    for (var i = 2; i <= 10; i++) {
      onProgreso?.call(i * _mb, total, 'onnx/vocoder.onnx');
    }
    return Directory('C:/modelo');
  }

  @override
  void cancelar() {
    cancelaciones++;
  }
}

/// Buscador de archivos falso: devuelve [resultado] sin tocar la plataforma.
class FilePickerFake extends FilePickerPlatform {
  FilePickerFake(this.resultado);

  FilePickerResult? resultado;

  int llamadas = 0;
  FileType? ultimoTipo;
  List<String>? ultimasExtensiones;
  bool? ultimoMultiple;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    llamadas++;
    ultimoTipo = type;
    ultimasExtensiones = allowedExtensions;
    ultimoMultiple = allowMultiple;
    return resultado;
  }
}

/// Stub de [ProcesarArchivo] que registra los argumentos y permite
/// bloquear/avanzar el procesamiento para probar cancelación y progreso.
class ProcesarArchivoStub extends ProcesarArchivo {
  ProcesarArchivoStub({
    required super.motor,
    required super.archivos,
    required super.exportador,
    required super.silencioMuestras,
    required super.memoriaSafeMarginBytes,
    required super.topeMovilBytes,
    super.esMovil,
  });

  final List<
      ({
        Archivo archivo,
        String rutaBase,
        int steps,
        double speed,
        List<String> formatos,
        String lang,
      })> llamadas = [];

  /// Si se define, `procesar` espera a que se complete antes de avanzar.
  Future<void> Function()? espera;

  /// Llamado antes de resolverse, para inyectar onProgreso/debeDetenerse.
  void Function(void Function(int, int) onProgreso, bool Function() detener)?
      alProcesar;

  /// Resultado devuelto por `procesar` (por defecto `ok`).
  ResultadoProceso resultado = ResultadoProceso.ok;

  @override
  Future<ResultadoProceso> procesar(
    Archivo archivo,
    String rutaBase, {
    required int steps,
    required double speed,
    required List<String> formatos,
    String lang = 'es',
    void Function(int actual, int total)? onProgreso,
    bool Function()? debeDetenerse,
  }) async {
    llamadas.add((
      archivo: archivo,
      rutaBase: rutaBase,
      steps: steps,
      speed: speed,
      formatos: formatos,
      lang: lang,
    ));
    await espera?.call();
    if (alProcesar != null && onProgreso != null && debeDetenerse != null) {
      alProcesar!(onProgreso, debeDetenerse);
    }
    return resultado;
  }
}
