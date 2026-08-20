/// Estima bytes de RAM necesarios para sintetizar un audio a partir de [chars].
int estimarBytesAudio(int chars) => (chars * 4.0).ceil();

/// Estima bytes totales de RAM para un lote de audios.
int estimarBytesLote(List<dynamic> audios) {
  var total = 0;
  for (final a in audios) {
    total += estimarBytesAudio(a.chars as int);
  }
  return total;
}

/// Fracción de memoria requerida (0.0–1.0+) sobre la disponible.
double fraccionMemoriaRequerida(int bytesRequeridos, int bytesDisponibles) {
  if (bytesDisponibles <= 0) return 1.0;
  return bytesRequeridos / bytesDisponibles;
}
