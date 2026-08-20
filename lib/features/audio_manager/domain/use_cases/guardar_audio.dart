import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';

/// Guarda un audio pendiente moviéndolo de [tempPath] a [carpetaDestino]/[nombreArchivo].
/// Resuelve conflictos de nombre con sufijo (N).
class GuardarAudio {
  GuardarAudio({required this.archivos});
  final RepositorioArchivos archivos;

  String ejecutar({
    required String tempPath,
    required String carpetaDestino,
    required String nombreArchivo,
  }) {
    archivos.crearCarpetasSiNoExisten([carpetaDestino]);
    var nombre = nombreArchivo;
    var destino = '$carpetaDestino$_sep$nombre';
    var contador = 1;
    while (archivos.existe(destino)) {
      final punto = nombre.lastIndexOf('.');
      if (punto > 0) {
        nombre = '${nombre.substring(0, punto)}($contador)${nombre.substring(punto)}';
      } else {
        nombre = '$nombre($contador)';
      }
      destino = '$carpetaDestino$_sep$nombre';
      contador++;
    }
    archivos.moverArchivo(tempPath, destino);
    return destino;
  }

  String get _sep => archivos.pathSeparator;
}
