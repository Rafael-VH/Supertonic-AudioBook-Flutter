import 'dart:io';

import 'package:supertonic_audiobook/core/utils/natural_sort.dart';
import 'package:supertonic_audiobook/domain/contracts/repositorio_archivos.dart';
import 'package:supertonic_audiobook/domain/entities/archivo.dart';

/// Implementación local (filesystem) de [RepositorioArchivos].
class RepositorioArchivosLocal implements RepositorioArchivos {
  @override
  void crearCarpetasSiNoExisten(List<String> carpetas) {
    for (final carpeta in carpetas) {
      Directory(carpeta).createSync(recursive: true);
    }
  }

  @override
  List<Archivo> listarArchivosMd(String carpeta) {
    final dir = Directory(carpeta);
    if (!dir.existsSync()) return [];

    final archivos = dir.listSync().whereType<File>().where(
          (f) => f.uri.pathSegments.last.toLowerCase().endsWith('.md'),
        ).toList();

    archivos.sort((a, b) {
      final claveA = naturalSortKey(_stem(a.uri.pathSegments.last));
      final claveB = naturalSortKey(_stem(b.uri.pathSegments.last));
      return compararNaturalSortKey(claveA, claveB);
    });
    return archivos.map((f) => Archivo(f.path)).toList();
  }

  @override
  String leerArchivo(String ruta) => File(ruta).readAsStringSync();
}

/// Nombre del archivo sin la última extensión (port de `Path.stem`).
String _stem(String nombre) {
  final i = nombre.lastIndexOf('.');
  return i <= 0 ? nombre : nombre.substring(0, i);
}
