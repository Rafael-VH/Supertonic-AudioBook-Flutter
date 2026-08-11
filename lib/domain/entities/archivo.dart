import 'package:equatable/equatable.dart';

/// Entidad de dominio: un archivo Markdown por convertir.
///
/// Paridad con `app/domain/entities/archivo.py`. La ruta se guarda como
/// String (el plan §4.2 así lo define); `nombre`/`titulo` se derivan de
/// ella sin depender de `dart:io` (dominio puro).
class Archivo extends Equatable {
  const Archivo(this.ruta);

  /// Ruta completa al archivo .md de entrada.
  final String ruta;

  /// Nombre del archivo con extensión (ej: 'archivo3.md').
  String get nombre {
    final normalizada = ruta.replaceAll('\\', '/');
    final idx = normalizada.lastIndexOf('/');
    return idx >= 0 ? normalizada.substring(idx + 1) : normalizada;
  }

  /// Nombre del archivo sin extensión (se usa para nombrar el audio).
  String get titulo {
    final n = nombre;
    final idx = n.lastIndexOf('.');
    return idx > 0 ? n.substring(0, idx) : n;
  }

  @override
  List<Object?> get props => [ruta];
}
