import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/features/biblioteca/domain/entities/libro_generado.dart';

/// Prioridad de formato: el índice menor gana (`mp3 > ogg > flac > wav`).
const _prioridadFormatos = ['mp3', 'ogg', 'flac', 'wav'];

/// Agrupa los audios generados por libro (stem) y elige el formato de mayor
/// prioridad disponible por libro (BIB-2). Puro: sin `dart:io` ni UI.
class ListarAudiosGenerados {
  ListarAudiosGenerados({required this._archivos});

  final RepositorioArchivos _archivos;

  /// Devuelve un `LibroGenerado` por stem, en el orden de primer encuentro
  /// (el repo ya devuelve orden natural: la extensión solo desempata
  /// intra-stem, que acá se agrupa — D4).
  ///
  /// Si se pasa [extras], también escanea esas carpetas y mezcla los
  /// resultados (sin duplicados por stem).
  List<LibroGenerado> ejecutar({
    required String carpeta,
    List<String>? extras,
  }) {
    final libros = <String, List<String>>{};
    final orden = <String>[];

    void scanDir(String dir) {
      for (final ruta in _archivos.listarAudios(dir)) {
        final stem = stemDeRuta(ruta);
        if (!libros.containsKey(stem)) orden.add(stem);
        libros.putIfAbsent(stem, () => []).add(ruta);
      }
    }

    scanDir(carpeta);
    if (extras != null) {
      for (final dir in extras) {
        scanDir(dir);
      }
    }

    return [
      for (final stem in orden)
        LibroGenerado(
          titulo: stem,
          archivos: libros[stem]!,
          formatoPrioritario: _formatoGanador(libros[stem]!),
        ),
    ];
  }

  static String _formatoGanador(List<String> rutas) {
    var ganador = formatoDeRuta(rutas.first);
    var mejorIndice = _prioridadFormatos.indexOf(ganador);
    for (final ruta in rutas.skip(1)) {
      final formato = formatoDeRuta(ruta);
      final indice = _prioridadFormatos.indexOf(formato);
      if (indice != -1 && (mejorIndice == -1 || indice < mejorIndice)) {
        ganador = formato;
        mejorIndice = indice;
      }
    }
    return ganador;
  }
}
