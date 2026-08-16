// Natural sort (port de `_natural_sort_key`, plan §5.4).
// Split del stem por (\d+) → tokens alternados texto/número; números como int
// (los que desbordan int64 como BigInt para comparar por valor, no por texto).
// Discriminador: 0 si el primer token es número, 1 si es texto.
// Clave: (discriminador, tokens, stem). Ordenar con esa clave.

/// Clave de orden natural para un nombre sin extensión.
({int discriminador, List<Object> tokens, String stem}) naturalSortKey(String stem) {
  final tokens = <Object>[];
  final re = RegExp(r'(\d+)');
  var ultimo = 0;
  for (final m in re.allMatches(stem)) {
    if (m.start > ultimo) tokens.add(stem.substring(ultimo, m.start));
    // Números que no caben en int64 (≥ 19 dígitos, p. ej. 9223372036854775808)
    // no deben lanzar ni compararse como texto: BigInt conserva el orden
    // numérico incluso mezclado con tokens int.
    final numToken = m.group(1)!;
    tokens.add(int.tryParse(numToken) ?? BigInt.parse(numToken));
    ultimo = m.end;
  }
  if (ultimo < stem.length) tokens.add(stem.substring(ultimo));
  if (tokens.isEmpty) tokens.add(stem);

  // BigInt NO es un num: el discriminador debe reconocer ambos tipos de token
  // numérico para que un stem cuyo primer token desborda int64 (BigInt) no se
  // agrupe como texto y quede separado de los demás prefijos numéricos.
  final empiezaConNumero = tokens.first is int || tokens.first is BigInt;
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
    } else if (x is BigInt && y is BigInt) {
      cmp = x.compareTo(y);
    } else if (x is int && y is BigInt) {
      // Los BigInt de acá nacen solo de números que no caben en int64:
      // siempre son mayores que cualquier int.
      cmp = -1;
    } else if (x is BigInt && y is int) {
      cmp = 1;
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
