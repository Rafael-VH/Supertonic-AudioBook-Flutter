// Natural sort (port de `_natural_sort_key`, plan §5.4).
// Split del stem por (\d+) → tokens alternados texto/número; números como int.
// Discriminador: 0 si el primer token es número, 1 si es texto.
// Clave: (discriminador, tokens, stem). Ordenar con esa clave.

/// Clave de orden natural para un nombre sin extensión.
({int discriminador, List<Object> tokens, String stem}) naturalSortKey(String stem) {
  final tokens = <Object>[];
  final re = RegExp(r'(\d+)');
  var ultimo = 0;
  for (final m in re.allMatches(stem)) {
    if (m.start > ultimo) tokens.add(stem.substring(ultimo, m.start));
    tokens.add(int.parse(m.group(1)!));
    ultimo = m.end;
  }
  if (ultimo < stem.length) tokens.add(stem.substring(ultimo));
  if (tokens.isEmpty) tokens.add(stem);

  final empiezaConNumero = tokens.first is int;
  return (discriminador: empiezaConNumero ? 0 : 1, tokens: tokens, stem: stem);
}

/// Compara dos claves de [naturalSortKey] (port de la comparación de tuplas).
int compararNaturalSortKey(
  ({int discriminador, List<Object> tokens, String stem}) a,
  ({int discriminador, List<Object> tokens, String stem}) b,
) {
  if (a.discriminador != b.discriminador) return a.discriminador.compareTo(b.discriminador);

  final tokensA = a.tokens;
  final tokensB = b.tokens;
  for (var i = 0; i < tokensA.length && i < tokensB.length; i++) {
    final x = tokensA[i];
    final y = tokensB[i];
    final int cmp;
    if (x is int && y is int) {
      cmp = x.compareTo(y);
    } else {
      cmp = x.toString().compareTo(y.toString());
    }
    if (cmp != 0) return cmp;
  }
  if (tokensA.length != tokensB.length) {
    return tokensA.length.compareTo(tokensB.length);
  }
  return a.stem.compareTo(b.stem);
}
