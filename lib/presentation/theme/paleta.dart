/// Paletas EXACTAS del port (plan §6.2 — paridad con `gui.py`).
///
/// Los hex de este archivo son los valores verificados; NO se inventan
/// variantes. Cada mapa se combina por overlay: base + overrides de estilo.
library;

import 'package:flutter/material.dart';

const Map<String, Color> paletaClara = {
  'fondo': Color(0xFFF4F1FA),
  'superficie': Color(0xFFFFFFFF),
  'superficie_variante': Color(0xFFE7E0EC),
  'primario': Color(0xFF6750A4),
  'primario_claro': Color(0xFFEADDFF),
  'primario_vivo': Color(0xFF7B67C8),
  'sobre_primario': Color(0xFFFFFFFF),
  'texto': Color(0xFF1C1B1F),
  'texto_secundario': Color(0xFF79747E),
  'borde': Color(0xFFCAC4D0),
  'advertencia': Color(0xFFB45309),
  'error': Color(0xFFB3261E),
  'error_vivo': Color(0xFFD0453E),
  'sobre_error': Color(0xFFFFFFFF),
  'snackbar_fondo': Color(0xFF322F35),
  'snackbar_texto': Color(0xFFFFFFFF),
};

const Map<String, Color> paletaOscura = {
  'fondo': Color(0xFF141218),
  'superficie': Color(0xFF211F26),
  'superficie_variante': Color(0xFF49454F),
  'primario': Color(0xFFD0BCFF),
  'primario_claro': Color(0xFF4F378B),
  'primario_vivo': Color(0xFFBBA6F4),
  'sobre_primario': Color(0xFF381E72),
  'texto': Color(0xFFE6E0E9),
  'texto_secundario': Color(0xFFCAC4D0),
  'borde': Color(0xFF4A4458),
  'advertencia': Color(0xFFFDD663),
  'error': Color(0xFFF2B8B5),
  'error_vivo': Color(0xFFF8C7C4),
  'sobre_error': Color(0xFF381E72),
  'snackbar_fondo': Color(0xFFE6E0E9),
  'snackbar_texto': Color(0xFF141218),
};

/// Overrides neumórficos: superficie == fondo; los elementos se distinguen
/// solo por biseles suaves (luz arriba-izquierda, sombra abajo-derecha).
const Map<String, Color> neumoClara = {
  'fondo': Color(0xFFE8E4F0),
  'superficie': Color(0xFFE8E4F0),
  'superficie_variante': Color(0xFFDDD8EA),
  'borde': Color(0xFFCFC9DE),
  'luz': Color(0xFFFDFBFF),
  'sombra': Color(0xFFC2BAD6),
  'primario_luz': Color(0xFFFFFFFF),
  'primario_sombra': Color(0xFF574E8C),
};

const Map<String, Color> neumoOscura = {
  'fondo': Color(0xFF1C1A23),
  'superficie': Color(0xFF1C1A23),
  'superficie_variante': Color(0xFF232029),
  'borde': Color(0xFF2C2836),
  'luz': Color(0xFF302C3C),
  'sombra': Color(0xFF0E0C12),
  'primario_luz': Color(0xFFE7D4FF),
  'primario_sombra': Color(0xFF8E77C8),
};

/// Overrides skeuomórficos: superficies grises neutras, biseles marcados y
/// acento azul acero.
const Map<String, Color> skeuoClara = {
  'fondo': Color(0xFFDEDEDE),
  'superficie': Color(0xFFEBEBEB),
  'superficie_variante': Color(0xFFCDCDCD),
  'borde': Color(0xFF9B9B9B),
  'luz': Color(0xFFFFFFFF),
  'sombra': Color(0xFF7F7F7F),
  'primario': Color(0xFF2E6DB4),
  'primario_claro': Color(0xFFD3E3F6),
  'primario_vivo': Color(0xFF3E7FC9),
  'primario_luz': Color(0xFF7FA8DE),
  'primario_sombra': Color(0xFF1F4A79),
  'sobre_primario': Color(0xFFFFFFFF),
};

const Map<String, Color> skeuoOscura = {
  'fondo': Color(0xFF3C3C3C),
  'superficie': Color(0xFF484848),
  'superficie_variante': Color(0xFF333333),
  'borde': Color(0xFF606060),
  'luz': Color(0xFF5C5C5C),
  'sombra': Color(0xFF222222),
  'primario': Color(0xFF4D8CD6),
  'primario_claro': Color(0xFF314B69),
  'primario_vivo': Color(0xFF5F9BE4),
  'primario_luz': Color(0xFF8AB4EA),
  'primario_sombra': Color(0xFF1E3A5C),
  'sobre_primario': Color(0xFFFFFFFF),
};

/// Estilo de interfaz (clave persistida `estilo`).
enum AppEstilo {
  material('material'),
  neumo('neumo'),
  skeuo('skeuo');

  const AppEstilo(this.id);

  /// Identificador persistido (paridad con `ESTILOS`).
  final String id;

  static AppEstilo desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return material;
  }
}

/// Paleta resuelta para una combinación (tema + estilo).
class Paleta {
  const Paleta({
    required this.fondo,
    required this.superficie,
    required this.superficieVariante,
    required this.primario,
    required this.primarioClaro,
    required this.primarioVivo,
    required this.sobrePrimario,
    required this.texto,
    required this.textoSecundario,
    required this.borde,
    required this.advertencia,
    required this.error,
    required this.errorVivo,
    required this.sobreError,
    required this.snackbarFondo,
    required this.snackbarTexto,
    required this.luz,
    required this.sombra,
    required this.primarioLuz,
    required this.primarioSombra,
  });

  /// Combina la paleta base del tema con los overrides del estilo
  /// (paridad con `_aplicar_tema`).
  factory Paleta.para({required bool oscuro, required AppEstilo estilo}) {
    final base = Map<String, Color>.of(oscuro ? paletaOscura : paletaClara);
    if (estilo == AppEstilo.neumo) {
      base.addAll(oscuro ? neumoOscura : neumoClara);
    } else if (estilo == AppEstilo.skeuo) {
      base.addAll(oscuro ? skeuoOscura : skeuoClara);
    }
    return Paleta.desdeMapa(base);
  }

  /// Construye desde un mapa con claves de la paleta. Los tonos de bisel que
  /// el estilo material no define se derivan de valores neutrales para que
  /// los widgets que los lean tengan siempre algo seguro.
  factory Paleta.desdeMapa(Map<String, Color> c) {
    return Paleta(
      fondo: c['fondo']!,
      superficie: c['superficie']!,
      superficieVariante: c['superficie_variante']!,
      primario: c['primario']!,
      primarioClaro: c['primario_claro']!,
      primarioVivo: c['primario_vivo']!,
      sobrePrimario: c['sobre_primario']!,
      texto: c['texto']!,
      textoSecundario: c['texto_secundario']!,
      borde: c['borde']!,
      advertencia: c['advertencia']!,
      error: c['error']!,
      errorVivo: c['error_vivo']!,
      sobreError: c['sobre_error']!,
      snackbarFondo: c['snackbar_fondo']!,
      snackbarTexto: c['snackbar_texto']!,
      luz: c['luz'] ?? c['superficie']!,
      sombra: c['sombra'] ?? c['borde']!,
      primarioLuz: c['primario_luz'] ?? c['primario_claro']!,
      primarioSombra: c['primario_sombra'] ?? c['primario']!,
    );
  }

  final Color fondo;
  final Color superficie;
  final Color superficieVariante;
  final Color primario;
  final Color primarioClaro;
  final Color primarioVivo;
  final Color sobrePrimario;
  final Color texto;
  final Color textoSecundario;
  final Color borde;
  final Color advertencia;
  final Color error;
  final Color errorVivo;
  final Color sobreError;
  final Color snackbarFondo;
  final Color snackbarTexto;
  final Color luz;
  final Color sombra;
  final Color primarioLuz;
  final Color primarioSombra;
}
