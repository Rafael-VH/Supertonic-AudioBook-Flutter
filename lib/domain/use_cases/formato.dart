/// Regla de negocio: formatos de salida soportados por el producto.
///
/// Paridad con `app/domain/use_cases/formato.py`.
library;

/// Formatos de salida soportados de forma nativa (sin ffmpeg).
const formatosNativos = ['wav', 'flac', 'ogg', 'mp3'];

/// Error de formato no soportado (paridad con `ValueError` de Python).
class FormatoInvalido implements Exception {
  const FormatoInvalido(this.formato);

  final String formato;

  @override
  String toString() {
    final validos = formatosNativos.join(', ');
    return "Formato no soportado: '$formato'. Válidos: $validos.";
  }
}

/// Normaliza una lista de formatos separada por comas.
///
/// Convierte a minúsculas, elimina espacios, ignora duplicados y conserva
/// el orden de aparición. Lanza [FormatoInvalido] si hay un formato
/// desconocido.
///
/// Paridad con `normalizar_formatos("wav,MP3")` → `['wav', 'mp3']`.
List<String> normalizarFormatos(String cadena) {
  final formatos = <String>[];
  for (final token in cadena.split(',')) {
    final formato = token.trim().toLowerCase();
    if (formato.isEmpty) continue;
    if (!formatosNativos.contains(formato)) {
      throw FormatoInvalido(formato);
    }
    if (!formatos.contains(formato)) {
      formatos.add(formato);
    }
  }
  return formatos;
}
