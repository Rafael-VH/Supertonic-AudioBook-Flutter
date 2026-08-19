/// Hangul Jamo constants for NFKD decomposition.
const int hangulSyllableBase = 0xAC00;
const int hangulSyllableEnd = 0xD7A3;
const int leadingJamoBase = 0x1100;
const int vowelJamoBase = 0x1161;
const int trailingJamoBase = 0x11A7;
const int vowelCount = 21;
const int trailingCount = 28;

/// Decompose a Hangul syllable into Jamo (NFKD-like decomposition).
List<int> decomposeHangulSyllable(int codePoint) {
  if (codePoint < hangulSyllableBase || codePoint > hangulSyllableEnd) {
    return [codePoint];
  }

  final syllableIndex = codePoint - hangulSyllableBase;
  final leadingIndex = syllableIndex ~/ (vowelCount * trailingCount);
  final vowelIndex =
      (syllableIndex % (vowelCount * trailingCount)) ~/ trailingCount;
  final trailingIndex = syllableIndex % trailingCount;

  final result = <int>[
    leadingJamoBase + leadingIndex,
    vowelJamoBase + vowelIndex,
  ];

  if (trailingIndex > 0) {
    result.add(trailingJamoBase + trailingIndex);
  }

  return result;
}

/// Common Latin character decompositions (NFKD) for es, pt, fr.
const Map<int, List<int>> latinDecompositions = {
  // Uppercase with acute accent
  0x00C1: [0x0041, 0x0301], // Á → A + ́
  0x00C9: [0x0045, 0x0301], // É → E + ́
  0x00CD: [0x0049, 0x0301], // Í → I + ́
  0x00D3: [0x004F, 0x0301], // Ó → O + ́
  0x00DA: [0x0055, 0x0301], // Ú → U + ́
  // Lowercase with acute accent
  0x00E1: [0x0061, 0x0301], // á → a + ́
  0x00E9: [0x0065, 0x0301], // é → e + ́
  0x00ED: [0x0069, 0x0301], // í → i + ́
  0x00F3: [0x006F, 0x0301], // ó → o + ́
  0x00FA: [0x0075, 0x0301], // ú → u + ́
  // Grave accent
  0x00C0: [0x0041, 0x0300], // À → A + ̀
  0x00C8: [0x0045, 0x0300], // È → E + ̀
  0x00CC: [0x0049, 0x0300], // Ì → I + ̀
  0x00D2: [0x004F, 0x0300], // Ò → O + ̀
  0x00D9: [0x0055, 0x0300], // Ù → U + ̀
  0x00E0: [0x0061, 0x0300], // à → a + ̀
  0x00E8: [0x0065, 0x0300], // è → e + ̀
  0x00EC: [0x0069, 0x0300], // ì → i + ̀
  0x00F2: [0x006F, 0x0300], // ò → o + ̀
  0x00F9: [0x0075, 0x0300], // ù → u + ̀
  // Circumflex
  0x00C2: [0x0041, 0x0302], // Â → A + ̂
  0x00CA: [0x0045, 0x0302], // Ê → E + ̂
  0x00CE: [0x0049, 0x0302], // Î → I + ̂
  0x00D4: [0x004F, 0x0302], // Ô → O + ̂
  0x00DB: [0x0055, 0x0302], // Û → U + ̂
  0x00E2: [0x0061, 0x0302], // â → a + ̂
  0x00EA: [0x0065, 0x0302], // ê → e + ̂
  0x00EE: [0x0069, 0x0302], // î → i + ̂
  0x00F4: [0x006F, 0x0302], // ô → o + ̂
  0x00FB: [0x0075, 0x0302], // û → u + ̂
  // Tilde
  0x00C3: [0x0041, 0x0303], // Ã → A + ̃
  0x00D1: [0x004E, 0x0303], // Ñ → N + ̃
  0x00D5: [0x004F, 0x0303], // Õ → O + ̃
  0x00E3: [0x0061, 0x0303], // ã → a + ̃
  0x00F1: [0x006E, 0x0303], // ñ → n + ̃
  0x00F5: [0x006F, 0x0303], // õ → o + ̃
  // Diaeresis/Umlaut
  0x00C4: [0x0041, 0x0308], // Ä → A + ̈
  0x00CB: [0x0045, 0x0308], // Ë → E + ̈
  0x00CF: [0x0049, 0x0308], // Ï → I + ̈
  0x00D6: [0x004F, 0x0308], // Ö → O + ̈
  0x00DC: [0x0055, 0x0308], // Ü → U + ̈
  0x00E4: [0x0061, 0x0308], // ä → a + ̈
  0x00EB: [0x0065, 0x0308], // ë → e + ̈
  0x00EF: [0x0069, 0x0308], // ï → i + ̈
  0x00F6: [0x006F, 0x0308], // ö → o + ̈
  0x00FC: [0x0075, 0x0308], // ü → u + ̈
  // Cedilla
  0x00C7: [0x0043, 0x0327], // Ç → C + ̧
  0x00E7: [0x0063, 0x0327], // ç → c + ̧
};

/// Apply NFKD-like decomposition (Hangul + Latin accented characters).
String applyNfkdDecomposition(String text) {
  final result = <int>[];
  for (final codePoint in text.runes) {
    // Check Hangul first
    if (codePoint >= hangulSyllableBase && codePoint <= hangulSyllableEnd) {
      result.addAll(decomposeHangulSyllable(codePoint));
    }
    // Check Latin decomposition
    else if (latinDecompositions.containsKey(codePoint)) {
      result.addAll(latinDecompositions[codePoint]!);
    }
    // Keep as-is
    else {
      result.add(codePoint);
    }
  }
  return String.fromCharCodes(result);
}
