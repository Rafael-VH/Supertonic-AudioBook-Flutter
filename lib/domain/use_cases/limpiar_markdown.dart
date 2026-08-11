/// Caso de uso puro: limpieza de Markdown a texto plano.
///
/// Paridad EXACTA con `app/domain/use_cases/limpiar_markdown.py`. Las reglas
/// se aplican en el mismo orden y con las mismas regex (Dart soporta
/// lookbehind y DOTALL, igual que el regex de Python).
library;

/// Reemplaza cada coincidencia por [reemplazo] literal.
String _reemplazar(RegExp re, String texto, String reemplazo) {
  return texto.replaceAll(re, reemplazo);
}

/// Reemplaza cada coincidencia por su grupo de captura 1.
///
/// Equivalente a `re.sub(re, r'\1', texto)` de Python; Dart no interpreta
/// `$1` dentro del string de `replaceAll`.
String _reemplazarPorGrupo1(RegExp re, String texto) {
  return texto.replaceAllMapped(re, (m) => m.group(1)!);
}

/// Elimina toda la sintaxis Markdown y devuelve texto plano legible.
String limpiarMarkdown(String texto) {
  // Bloques de código ANTES que títulos/negrita/inline: el patrón `{1,3}`
  // de inline consume los backticks de apertura de un bloque ``` y lo rompe.
  texto = _reemplazar(RegExp(r'~~~.*?~~~', dotAll: true), texto, '');
  texto = _reemplazar(RegExp(r'```.*?```', dotAll: true), texto, '');
  texto = _reemplazar(RegExp(r'^#{1,6}\s*', multiLine: true), texto, '');
  // Énfasis con asteriscos en pasadas separadas por conteo exacto (***, **, *):
  // el delimitador no puede estar adyacente a espacio, a otro asterisco ni ser
  // intraword, así "2 * 3 * 4", "a*b*c" o el "***" de prosa no se confunden.
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<![\w*])\*{3}(?![\s*])(.*?)(?<![\s*])\*{3}(?![\w*])'), texto);
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<![\w*])\*{2}(?![\s*])(.*?)(?<![\s*])\*{2}(?![\w*])'), texto);
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<![\w*])\*{1}(?![\s*])(.*?)(?<![\s*])\*{1}(?![\w*])'), texto);
  // Subrayado de énfasis con las mismas reglas: "clave_privada" no es énfasis.
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<!\w)_{3}(?![\s_])(.*?)(?<![\s_])_{3}(?!\w)'), texto);
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<!\w)_{2}(?![\s_])(.*?)(?<![\s_])_{2}(?!\w)'), texto);
  texto = _reemplazarPorGrupo1(
      RegExp(r'(?<!\w)_{1}(?![\s_])(.*?)(?<![\s_])_{1}(?!\w)'), texto);
  texto = _reemplazarPorGrupo1(RegExp(r'`{1,3}(.*?)`{1,3}'), texto);
  // Imágenes ANTES que links: el patrón genérico de link dejaría el "!".
  texto = _reemplazarPorGrupo1(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), texto);
  texto = _reemplazarPorGrupo1(RegExp(r'\[([^\]]+)\]\([^)]+\)'), texto);
  // Blockquotes anclados al inicio de línea: sin ancla, "5 > 3" perdería el
  // operador de comparación en medio de la prosa.
  texto = _reemplazar(RegExp(r'^\s*>\s?', multiLine: true), texto, '');
  // Líneas horizontales ancladas a la línea completa: "a---b" o "x***y" en
  // prosa no son HR. Acepta 3+ marcadores con o sin espacio. Va ANTES de las
  // listas para que "* * *" o "- - -" no queden mutilados por las viñetas.
  texto = _reemplazar(
      RegExp(r'^\s*(?:-{3,}|\*{3,}|(?:\*[ \t]*){3,}|(?:-[ \t]*){3,})\s*$',
          multiLine: true),
      texto,
      '');
  // Listas ancladas al inicio de línea: sin el ancla, "- x + y" o "a * b"
  // perderían sus operadores en medio de la prosa.
  texto = _reemplazar(RegExp(r'^\s*[-*+]\s+', multiLine: true), texto, '');
  // Listas ordenadas (hasta 3 dígitos): "2024. Cifra..." es prosa con año.
  texto =
      _reemplazar(RegExp(r'^\s*\d{1,3}[.)]\s+', multiLine: true), texto, '');
  texto = _reemplazar(RegExp(r'\n{3,}'), texto, '\n\n');
  return texto.trim();
}
