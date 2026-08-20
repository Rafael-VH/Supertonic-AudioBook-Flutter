import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';

/// Guarda un audio pendiente moviéndolo de [tempPath] a [carpetaDestino]/[nombreArchivo].
/// Resuelve conflictos de nombre con sufijo (N).
class GuardarAudio {
  GuardarAudio({required this._archivos});
  final RepositorioArchivos _archivos;

  String ejecutar({
    required String tempPath,
    required String carpetaDestino,
    required String nombreArchivo,
  }) {
    _archivos.crearCarpetasSiNoExisten([carpetaDestino]);
    var nombre = nombreArchivo;
    var destino = '$carpetaDestino$_sep$nombre';
    var contador = 1;
    while (_archivos.existe(destino)) {
      final punto = nombre.lastIndexOf('.');
      if (punto > 0) {
        nombre = '${nombre.substring(0, punto)}($contador)${nombre.substring(punto)}';
      } else {
        nombre = '$nombre($contador)';
      }
      destino = '$carpetaDestino$_sep$nombre';
      contador++;
    }
    _archivos.moverArchivo(tempPath, destino);
    return destino;
  }

  String get _sep => _archivos.pathSeparator;
}
