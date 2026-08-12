import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:supertonic_audiobook/domain/contracts/modelo_gestor.dart';

/// Archivo publicado en el repo HuggingFace de supertonic-3.
class ArchivoModelo {
  final String ruta;
  final int tamanoBytes;
  final String? sha256;

  const ArchivoModelo(this.ruta, this.tamanoBytes, this.sha256);
}

/// Archivos del repo https://huggingface.co/Supertone/supertonic-3
/// Los SHA-256 de los ONNX son los `lfs.oid` publicados por HF.
/// JSONs y estilos de voz no tienen hash publicado: se validan por tamaño
/// exacto y parseo.
const List<ArchivoModelo> archivosModelo = [
  ArchivoModelo(
    'onnx/duration_predictor.onnx',
    3700147,
    'c3eb91414d5ff8a7a239b7fe9e34e7e2bf8a8140d8375ffb14718b1c639325db',
  ),
  ArchivoModelo(
    'onnx/text_encoder.onnx',
    36416150,
    'c7befd5ea8c3119769e8a6c1486c4edc6a3bc8365c67621c881bbb774b9902ff',
  ),
  ArchivoModelo(
    'onnx/vector_estimator.onnx',
    256534781,
    '883ac868ea0275ef0e991524dc64f16b3c0376efd7c320af6b53f5b780d7c61c',
  ),
  ArchivoModelo(
    'onnx/vocoder.onnx',
    101424195,
    '085de76dd8e8d5836d6ca66826601f615939218f90e519f70ee8a36ed2a4c4ba',
  ),
  ArchivoModelo('onnx/tts.json', 8253, null),
  ArchivoModelo('onnx/unicode_indexer.json', 277676, null),
  ArchivoModelo('voice_styles/F1.json', 292046, null),
  ArchivoModelo('voice_styles/F2.json', 292423, null),
  ArchivoModelo('voice_styles/F3.json', 290794, null),
  ArchivoModelo('voice_styles/F4.json', 291808, null),
  ArchivoModelo('voice_styles/F5.json', 291479, null),
  ArchivoModelo('voice_styles/M1.json', 291748, null),
  ArchivoModelo('voice_styles/M2.json', 292055, null),
  ArchivoModelo('voice_styles/M3.json', 290198, null),
  ArchivoModelo('voice_styles/M4.json', 291522, null),
  ArchivoModelo('voice_styles/M5.json', 291469, null),
];

/// Descarga el modelo supertonic-3 (NO se empaqueta en el build).
///
/// Estrategia (plan §5.5):
/// - Descarga en runtime a `getApplicationSupportDirectory()/modelo`, el
///   directorio propio de la app (aislado de la carpeta Documents del usuario).
/// - Resumible con `dio` (header `Range`, modo append sobre un `.part`).
/// - Verificación de integridad: SHA-256 para los ONNX, tamaño exacto + parseo
///   JSON para los archivos de configuración y estilos de voz.
class ModeloManager implements ModeloGestor {
  static const String urlBase =
      'https://huggingface.co/Supertone/supertonic-3/resolve/main';

  final Dio _dio;

  /// Descarga activa, para poder cancelarla desde la presentación.
  CancelToken? _activo;

  ModeloManager({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> _directorioModelo() async {
    final soporte = await getApplicationSupportDirectory();
    final dir = Directory('${soporte.path}${Platform.pathSeparator}modelo');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Garantiza el modelo descargado y verificado. Devuelve el directorio raíz.
  ///
  /// [onProgreso] recibe `(bytesDescargados, bytesTotales, archivoActual)`.
  @override
  Future<Directory> asegurarModelo({
    void Function(int bytes, int total, String archivo)? onProgreso,
  }) async {
    final raiz = await _directorioModelo();
    final token = _activo = CancelToken();
    try {
      final totalBytes = archivosModelo
          .map((a) => a.tamanoBytes)
          .fold<int>(0, (sum, n) => sum + n);
      var descargados = 0;

      for (final archivo in archivosModelo) {
        final destino =
            File('${raiz.path}${Platform.pathSeparator}${archivo.ruta}');
        await destino.parent.create(recursive: true);

        if (await _estaVerificado(destino, archivo)) {
          descargados += archivo.tamanoBytes;
          onProgreso?.call(descargados, totalBytes, archivo.ruta);
          continue;
        }

        final part = File('${destino.path}.part');
        if (await part.exists()) {
          final tamano = await part.length();
          if (tamano > archivo.tamanoBytes) {
            await part.delete();
          }
        }

        var intentos = 0;
        var ok = false;
        while (!ok && intentos < 3) {
          intentos++;
          try {
            await _descargar(archivo, part, onProgreso,
                yaDescargados: descargados, totalBytes: totalBytes);
            final verificada = await _verificar(part, archivo);
            if (!verificada) {
              throw Exception(
                  'Integridad fallida para ${archivo.ruta} (SHA-256 o tamaño no coincide)');
            }
            await part.rename(destino.path);
            ok = true;
          } on DioException catch (e) {
            if (e.type == DioExceptionType.cancel) {
              rethrow;
            }
            if (intentos >= 3) rethrow;
          }
        }

        descargados += archivo.tamanoBytes;
        onProgreso?.call(descargados, totalBytes, archivo.ruta);
      }

      return raiz;
    } finally {
      if (identical(_activo, token)) _activo = null;
    }
  }

  /// Comprueba si el modelo ya está completo y verificado en disco.
  @override
  Future<bool> verificarDisponible() async {
    final raiz = await _directorioModelo();
    for (final archivo in archivosModelo) {
      final destino =
          File('${raiz.path}${Platform.pathSeparator}${archivo.ruta}');
      if (!await _estaVerificado(destino, archivo)) return false;
    }
    return true;
  }

  /// Cancela la descarga en curso (no-op si no hay ninguna activa).
  @override
  void cancelar() {
    _activo?.cancel();
    _activo = null;
  }

  Future<bool> _estaVerificado(File destino, ArchivoModelo archivo) async {
    if (!await destino.exists()) return false;
    final tamano = await destino.length();
    if (tamano != archivo.tamanoBytes) return false;
    if (archivo.sha256 != null) {
      return await _hashSha256(destino) == archivo.sha256;
    }
    return _esJsonValido(destino);
  }

  Future<void> _descargar(
    ArchivoModelo archivo,
    File part,
    void Function(int bytes, int total, String archivo)? onProgreso, {
    required int yaDescargados,
    required int totalBytes,
  }) async {
    final url = '$urlBase/${archivo.ruta}';
    final inicio = await part.exists() ? await part.length() : 0;

    await _dio.download(
      url,
      part.path,
      cancelToken: _activo,
      deleteOnError: false,
      fileAccessMode: FileAccessMode.append,
      options: Options(
        headers: {
          if (inicio > 0) 'range': 'bytes=$inicio-',
        },
      ),
      onReceiveProgress: (recibidos, _) {
        onProgreso?.call(
          yaDescargados + inicio + recibidos,
          totalBytes,
          archivo.ruta,
        );
      },
    );
  }

  Future<bool> _verificar(File part, ArchivoModelo archivo) async {
    final tamano = await part.length();
    if (tamano != archivo.tamanoBytes) return false;
    if (archivo.sha256 != null) {
      return await _hashSha256(part) == archivo.sha256;
    }
    return _esJsonValido(part);
  }

  Future<String> _hashSha256(File archivo) async {
    final digest = await sha256.bind(archivo.openRead()).first;
    return digest.toString();
  }

  bool _esJsonValido(File archivo) {
    try {
      jsonDecode(archivo.readAsStringSync());
      return true;
    } catch (_) {
      return false;
    }
  }
}
