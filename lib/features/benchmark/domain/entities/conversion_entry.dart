/// Entrada de historial de conversiones exitosas.
///
/// Captura las métricas de un archivo convertido a audio, para persistencia
/// y visualización en el historial de benchmarks.
class ConversionEntry {
  const ConversionEntry({
    required this.nombreArchivo,
    required this.caracteres,
    required this.segmentos,
    required this.duracionAudioSeg,
    required this.fecha,
  });

  final String nombreArchivo;
  final int caracteres;
  final int segmentos;
  final double duracionAudioSeg;
  final DateTime fecha;

  Map<String, Object?> toMap() => {
        'nombreArchivo': nombreArchivo,
        'caracteres': caracteres,
        'segmentos': segmentos,
        'duracionAudioSeg': duracionAudioSeg,
        'fecha': fecha.toIso8601String(),
      };

  factory ConversionEntry.fromMap(Map<String, Object?> map) {
    return ConversionEntry(
      nombreArchivo: map['nombreArchivo'] as String? ?? '',
      caracteres: (map['caracteres'] as num?)?.toInt() ?? 0,
      segmentos: (map['segmentos'] as num?)?.toInt() ?? 0,
      duracionAudioSeg:
          (map['duracionAudioSeg'] as num?)?.toDouble() ?? 0,
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
