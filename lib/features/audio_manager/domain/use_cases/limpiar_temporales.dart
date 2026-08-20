import 'package:supertonic_audiobook/shared/domain/contracts/repositorio_archivos.dart';

/// Elimina archivos WAV en [carpetaTemp] con más de 24 horas.
class LimpiarTemporales {
  LimpiarTemporales({required this.archivos});
  final RepositorioArchivos archivos;

  static const _maxEdad = Duration(hours: 24);

  void ejecutar({required String carpetaTemp}) {
    final ahora = DateTime.now();
    for (final ruta in archivos.listarAudios(carpetaTemp)) {
      final mod = archivos.fechaModificacion(ruta);
      if (mod != null && ahora.difference(mod) > _maxEdad) {
        archivos.eliminarSiExiste(ruta);
      }
    }
  }
}
