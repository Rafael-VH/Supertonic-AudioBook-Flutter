import '../entities/archivo.dart';

/// Acceso a los archivos Markdown de entrada (contrato de dominio).
abstract class RepositorioArchivos {
  /// Crea las carpetas indicadas si no existen.
  void crearCarpetasSiNoExisten(List<String> carpetas);

  /// Busca archivos `.md` en [carpeta] y los ordena numéricamente.
  List<Archivo> listarArchivosMd(String carpeta);

  /// Lee el contenido UTF-8 de un archivo.
  String leerArchivo(String ruta);
}
