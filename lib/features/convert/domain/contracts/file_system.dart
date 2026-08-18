/// Operaciones de filesystem que el dominio necesita, abstraídas para no
/// depender de `dart:io`. La implementación concreta vive en `data/` y se
/// inyecta desde la composición.
abstract class FileSystemContract {
  /// Devuelve el directorio padre de [ruta].
  String parentOf(String ruta);

  /// Crea el directorio en [ruta] (recursivo si no existe).
  void createDirectory(String ruta);

  /// Crea un archivo vacío en [ruta]. No-op si ya existe.
  void createFile(String ruta);

  /// Devuelve `true` si el archivo en [ruta] existe.
  bool fileExists(String ruta);

  /// Elimina el archivo en [ruta]. No-op si no existe.
  void deleteFile(String ruta);

  /// Renombra [origen] a [destino]. Devuelve `true` en éxito.
  ///
  /// En Windows, ERROR_SHARING_VIOLATION (32) y en POSIX EACCES (13)
  /// significan "archivo en uso": la implementación debe devolver `false`
  /// en ese caso (no lanzar).
  bool renameFile(String origen, String destino);

  /// Extrae el nombre del archivo (con extensión) de una ruta completa.
  String fileName(String ruta);

  /// El separador de ruta de la plataforma (`/` o `\`).
  String get pathSeparator;
}
