import 'package:supertonic_audiobook/features/convert/data/helpers/unicode_constants.dart';

/// Available languages for multilingual TTS.
const List<String> availableLangs = [
  'en', 'ko', 'ja', 'ar', 'bg', 'cs', 'da', 'de', 'el', 'es', 'et', 'fi',
  'fr', 'hi', 'hr', 'hu', 'id', 'it', 'lt', 'lv', 'nl', 'pl', 'pt', 'ro',
  'ru', 'sk', 'sl', 'sv', 'tr', 'uk', 'vi', 'na',
];

/// Check if a language code is valid.
bool isValidLang(String lang) => availableLangs.contains(lang);

/// Preprocess text for TTS inference.
///
/// Applies NFKD decomposition, removes emojis, replaces symbols,
/// fixes spacing, validates language, and wraps with language tags.
String preprocessText(String text, String lang) {
  // Apply NFKD-like decomposition (especially for Hangul syllables → Jamo)
  text = applyNfkdDecomposition(text);

  // Remove emojis
  text = text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
        r'[\u{1F700}-\u{1F77F}]|[\u{1F780}-\u{1F7FF}]|[\u{1F800}-\u{1F8FF}]|'
        r'[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|'
        r'[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '');

  // Replace various dashes and symbols
  const replacements = {
    '–': '-',
    '‑': '-',
    '—': '-',
    '_': ' ',
    '\u201C': '"',
    '\u201D': '"',
    '\u2018': "'",
    '\u2019': "'",
    '´': "'",
    '`': "'",
    '[': ' ',
    ']': ' ',
    '|': ' ',
    '/': ' ',
    '#': ' ',
    '→': ' ',
    '←': ' ',
  };
  for (final entry in replacements.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }

  // Remove special symbols
  text = text.replaceAll(RegExp(r'[♥☆♡©\\]'), '');

  // Replace known expressions
  text = text.replaceAll('@', ' at ');
  text = text.replaceAll('e.g.,', 'for example, ');
  text = text.replaceAll('i.e.,', 'that is, ');

  // Fix spacing around punctuation
  text = text.replaceAll(' ,', ',');
  text = text.replaceAll(' .', '.');
  text = text.replaceAll(' !', '!');
  text = text.replaceAll(' ?', '?');
  text = text.replaceAll(' ;', ';');
  text = text.replaceAll(' :', ':');
  text = text.replaceAll(" '", "'");

  // Remove duplicate quotes
  while (text.contains('""')) {
    text = text.replaceAll('""', '"');
  }
  while (text.contains("''")) {
    text = text.replaceAll("''", "'");
  }
  while (text.contains('``')) {
    text = text.replaceAll('``', '`');
  }

  // Remove extra spaces
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Add period if needed
  if (text.isNotEmpty &&
      !RegExp(r'[.!?;:,\x27\x22\u2018\u2019)\]}…。」』】〉》›»]$')
          .hasMatch(text)) {
    text += '.';
  }

  // Validate language
  if (!isValidLang(lang)) {
    throw ArgumentError(
        'Invalid language: $lang. Available: ${availableLangs.join(", ")}');
  }

  // Wrap text with language tags
  text = '<$lang>$text</$lang>';

  return text;
}
