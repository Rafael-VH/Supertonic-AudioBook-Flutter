/// Caso de uso puro: segmentación de texto apto para TTS.
///
/// Paridad con `app/domain/use_cases/segmentar_texto.py`, incluyendo el
/// comportamiento verificado ("doble punto" en la unión de
/// oraciones y segmentos que exceden el límite).
library;

/// Máximo de caracteres por fragmento de audio.
const maxCharsPerSegment = 1500;

/// Párrafos con menos caracteres que este valor se fusionan con el siguiente.
const mergeThreshold = 200;

const _abreviaturas = [
  'Dr', 'Dra', 'Sr', 'Sra', 'Sta', 'Sto', 'etc', 'i.e', 'e.g', 'vs',
  'Lic', 'Ing', 'Mtro', 'Mtra', 'Prof', 'Gral',
];

/// Divide [texto] en oraciones respetando abreviaturas del español.
///
/// Python `re` no permite lookbehind de ancho variable; Dart sí, pero se
/// mantiene el mismo enfoque (proteger puntos de abreviaturas con `\x00`,
/// split por `. ` y restaurar) para garantizar paridad de comportamiento.
List<String> _dividirEnOraciones(String texto) {
  var protegido = texto;
  for (final abr in _abreviaturas) {
    protegido = protegido.replaceAll('$abr.', '$abr\x00');
  }
  final subfrases = protegido.split(RegExp(r'(?<=\.)\s+'));
  return subfrases.map((f) => f.replaceAll('\x00', '.')).toList();
}

/// Divide texto plano en segmentos aptos para el TTS.
List<String> segmentarTexto(String textoPlano) {
  final parrafos = textoPlano
      .split('\n')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  // --- 1. Fusión de párrafos cortos ---
  final fusionados = <String>[];
  var buffer = '';
  for (final p in parrafos) {
    if (buffer.isEmpty) {
      buffer = p;
    } else if (buffer.length + p.length < maxCharsPerSegment &&
        p.length < mergeThreshold) {
      buffer += ' $p';
    } else {
      fusionados.add(buffer);
      buffer = p;
    }
  }
  if (buffer.isNotEmpty) fusionados.add(buffer);

  // --- 2. División de párrafos largos ---
  final resultado = <String>[];
  for (final p in fusionados) {
    if (p.length <= maxCharsPerSegment) {
      resultado.add(p);
      continue;
    }

    final subfrases = _dividirEnOraciones(p);
    var bufferFrase = '';
    for (final frase in subfrases) {
      if (bufferFrase.length + frase.length + 2 <= maxCharsPerSegment) {
        bufferFrase += '$frase. ';
      } else {
        resultado.add(bufferFrase.trim());
        bufferFrase = '$frase. ';
      }
    }
    if (bufferFrase.isNotEmpty) resultado.add(bufferFrase.trim());
  }

  return resultado;
}
