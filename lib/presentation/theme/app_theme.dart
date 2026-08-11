import 'package:flutter/material.dart';

import 'paleta.dart';

/// Extensión de tema con los colores de la paleta del port (§6.2) que
/// Material 3 no modela (biseles luz/sombra, snackbar, advertencia, etc.).
/// Los widgets lo leen con `PaletaExt.of(context)`.
class PaletaExt extends ThemeExtension<PaletaExt> {
  const PaletaExt({required this.paleta, required this.estilo});

  final Paleta paleta;
  final AppEstilo estilo;

  static PaletaExt? of(BuildContext context) =>
      Theme.of(context).extension<PaletaExt>();

  @override
  PaletaExt copyWith({Paleta? paleta, AppEstilo? estilo}) {
    return PaletaExt(
      paleta: paleta ?? this.paleta,
      estilo: estilo ?? this.estilo,
    );
  }

  @override
  PaletaExt lerp(PaletaExt? other, double t) {
    if (other == null) return this;
    return PaletaExt(
      paleta: other.paleta,
      estilo: t < 0.5 ? estilo : other.estilo,
    );
  }
}

/// Construye el [ThemeData] para una combinación tema + estilo usando las
/// paletas EXACTAS del port (§6.2).
///
/// El colorScheme se arma de forma explícita (sin `ColorScheme.fromSeed`)
/// porque los hex de la paleta son los que mandan.
ThemeData construirTema({required bool oscuro, required AppEstilo estilo}) {
  final p = Paleta.para(oscuro: oscuro, estilo: estilo);
  final scheme = ColorScheme(
    brightness: oscuro ? Brightness.dark : Brightness.light,
    primary: p.primario,
    onPrimary: p.sobrePrimario,
    primaryContainer: p.primarioClaro,
    onPrimaryContainer: p.texto,
    secondary: p.primarioVivo,
    onSecondary: p.sobrePrimario,
    secondaryContainer: p.primarioClaro,
    onSecondaryContainer: p.texto,
    tertiary: p.primarioVivo,
    onTertiary: p.sobrePrimario,
    error: p.error,
    onError: p.sobreError,
    errorContainer: p.errorVivo,
    onErrorContainer: p.sobreError,
    surface: p.superficie,
    onSurface: p.texto,
    onSurfaceVariant: p.textoSecundario,
    surfaceContainerHighest: p.superficieVariante,
    outline: p.borde,
    outlineVariant: p.borde,
    shadow: p.sombra,
    scrim: p.sombra,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.fondo,
    extensions: [PaletaExt(paleta: p, estilo: estilo)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.superficie,
      foregroundColor: p.texto,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: p.texto,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.borde),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.borde),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.snackbarFondo,
      contentTextStyle: TextStyle(color: p.snackbarTexto),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.primario, width: 2),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: p.borde),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.primario : null,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primario,
        foregroundColor: p.sobrePrimario,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primario,
        side: BorderSide(color: p.borde),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primario),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.primario,
      inactiveTrackColor: p.superficieVariante,
      thumbColor: p.primarioVivo,
      overlayColor: p.primarioClaro.withValues(alpha: 0.4),
      valueIndicatorColor: p.primario,
      valueIndicatorTextStyle: TextStyle(color: p.sobrePrimario),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.primario,
      textColor: p.texto,
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: p.texto),
      bodySmall: TextStyle(color: p.textoSecundario),
      titleMedium: TextStyle(color: p.texto),
      labelLarge: TextStyle(color: p.texto),
    ),
  );
}
