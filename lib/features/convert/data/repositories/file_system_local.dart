import 'dart:io';

import 'package:supertonic_audiobook/features/convert/domain/contracts/file_system.dart';

/// Implementación de [FileSystemContract] que delega a `dart:io`.
class FileSystemLocal implements FileSystemContract {
  @override
  String parentOf(String ruta) => File(ruta).parent.path;

  @override
  void createDirectory(String ruta) => Directory(ruta).createSync(recursive: true);

  @override
  void createFile(String ruta) => File(ruta).createSync();

  @override
  bool fileExists(String ruta) => File(ruta).existsSync();

  @override
  void deleteFile(String ruta) {
    try {
      File(ruta).deleteSync();
    } catch (_) {
      // FileNotFoundError / PermissionError → ignorar (paridad).
    }
  }

  @override
  bool renameFile(String origen, String destino) {
    try {
      File(origen).renameSync(destino);
      return true;
    } on FileSystemException catch (e) {
      // EACCES (13) en POSIX y ERROR_SHARING_VIOLATION (32) en Windows son el
      // "archivo en uso"; no se actualiza la salida en ese caso.
      if (e.osError?.errorCode == 13 || e.osError?.errorCode == 32) {
        return false;
      }
      rethrow;
    }
  }

  @override
  String fileName(String ruta) => File(ruta).uri.pathSegments.last;

  @override
  int fileLastModified(String ruta) {
    try {
      return File(ruta).lastModifiedSync().millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  @override
  List<String> listDirectory(String ruta) {
    try {
      return Directory(ruta)
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String get pathSeparator => Platform.pathSeparator;
}
