import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Parsea un archivo ARB y devuelve sus claves de traducción (sin @@ metadatos).
Map<String, String> _cargarArb(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final e in raw.entries)
      if (e.key is String && !e.key.startsWith('@@') && e.value is String)
        e.key: e.value! as String,
  };
}

/// Extrae los placeholders de un valor ARB: `{nombre}` → `{'nombre'}`.
Set<String> _placeholders(String valor) {
  return RegExp(r'\{(\w+)\}')
      .allMatches(valor)
      .map((m) => m.group(1)!)
      .toSet();
}

const _es = 'lib/presentation/l10n/app_es.arb';
const _en = 'lib/presentation/l10n/app_en.arb';

void main() {
  late Map<String, String> es;
  late Map<String, String> en;

  setUpAll(() {
    es = _cargarArb(_es);
    en = _cargarArb(_en);
  });

  test('paridad exacta de claves es/en', () {
    expect(es.keys, containsAll(en.keys));
    expect(en.keys, containsAll(es.keys));
  });

  test('placeholders coinciden por clave entre idiomas', () {
    for (final clave in es.keys) {
      final phEs = _placeholders(es[clave]!);
      final phEn = _placeholders(en[clave]!);
      expect(phEs, phEn, reason: 'Placeholder mismatch en "$clave"');
    }
  });

  test('AppLocalizations.supportedLocales contiene es y en', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
  });

  test('lookupAppLocalizations resuelve una clave para es y en', () {
    final locEs = lookupAppLocalizations(const Locale('es'));
    final locEn = lookupAppLocalizations(const Locale('en'));

    // La clave 'cerrar' existe en ambos ARBs (Close / Cerrar).
    expect(locEs.cerrar, isNotEmpty);
    expect(locEn.cerrar, isNotEmpty);
    expect(locEs.cerrar, isNot(equals(locEn.cerrar)));
  });
}
