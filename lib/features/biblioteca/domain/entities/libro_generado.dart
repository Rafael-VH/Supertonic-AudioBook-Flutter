import 'package:equatable/equatable.dart';

/// Deriva el nombre de archivo (con extensión) de una [ruta] sin depender de
/// `dart:io` (dominio puro), normalizando separadores de Windows.
/// Paridad con `Archivo.nombre`.
String nombreDeRuta(String ruta) {
  final normalizada = ruta.replaceAll('\\', '/');
  final idx = normalizada.lastIndexOf('/');
  return idx >= 0 ? normalizada.substring(idx + 1) : normalizada;
}

/// Stem de [ruta]: nombre sin la última extensión (BIB-2).
/// Paridad con `Archivo.titulo`.
String stemDeRuta(String ruta) {
  final n = nombreDeRuta(ruta);
  final idx = n.lastIndexOf('.');
  return idx > 0 ? n.substring(0, idx) : n;
}

/// Formato de [ruta] (extensión sin punto, en minúsculas); '' si no tiene.
String formatoDeRuta(String ruta) {
  final n = nombreDeRuta(ruta);
  final idx = n.lastIndexOf('.');
  return idx > 0 ? n.substring(idx + 1).toLowerCase() : '';
}

/// Un audiolibro generado: agrupa las rutas de audio de un mismo stem
/// (nombre sin última extensión) y recuerda el formato ganador según la
/// prioridad `mp3 > ogg > flac > wav` (BIB-2).
class LibroGenerado extends Equatable {
  const LibroGenerado({
    required this.titulo,
    required this.archivos,
    required this.formatoPrioritario,
  });

  /// Nombre del libro (stem del archivo, ej: 'milibro').
  final String titulo;

  /// Rutas completas de los audios del libro, en orden natural.
  final List<String> archivos;

  /// Formato ganador del libro: 'mp3' | 'ogg' | 'flac' | 'wav'.
  final String formatoPrioritario;

  /// Ruta del audio a reproducir: la primera [archivos] con el formato
  /// ganador (el ganador siempre está presente por construcción del use case).
  String get rutaPrioritaria {
    for (final ruta in archivos) {
      if (formatoDeRuta(ruta) == formatoPrioritario) return ruta;
    }
    return archivos.first;
  }

  @override
  List<Object?> get props => [titulo, archivos, formatoPrioritario];
}
