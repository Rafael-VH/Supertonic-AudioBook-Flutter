import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

/// Estado de los ajustes de interfaz (plan §6.3, claves exactas).
class SettingsEstado {
  const SettingsEstado({
    required this.temaOscuro,
    required this.estilo,
    required this.idioma,
    required this.carpetaOut,
  });

  final bool temaOscuro;
  final AppEstilo estilo;
  final String idioma;
  final String carpetaOut;

  SettingsEstado copyWith({
    bool? temaOscuro,
    AppEstilo? estilo,
    String? idioma,
    String? carpetaOut,
  }) {
    return SettingsEstado(
      temaOscuro: temaOscuro ?? this.temaOscuro,
      estilo: estilo ?? this.estilo,
      idioma: idioma ?? this.idioma,
      carpetaOut: carpetaOut ?? this.carpetaOut,
    );
  }
}

/// Ajustes de la interfaz. Los valores iniciales se cargan del repositorio
/// inyectado (claves de §6.3) y cada cambio se persiste de inmediato.
class SettingsController extends Notifier<SettingsEstado> {
  @override
  SettingsEstado build() {
    final preferencias = ref.watch(repositorioPreferenciasProvider).cargar();
    final base = ref.watch(carpetaBaseProvider);
    return SettingsEstado(
      temaOscuro: preferencias['tema_oscuro'] as bool? ?? false,
      estilo: AppEstilo.desdeId(preferencias['estilo'] as String?),
      idioma: preferencias['idioma'] as String? ?? 'es',
      carpetaOut: preferencias['carpeta_out'] as String? ??
          '$base${Platform.pathSeparator}audio',
    );
  }

  void _persistir() {
    // Merge: el mismo repositorio guarda las claves de Home (§6.3) y no debe
    // borrarlas al persistir solo las de interfaz.
    final prefs = {
      ...ref.read(repositorioPreferenciasProvider).cargar(),
      'tema_oscuro': state.temaOscuro,
      'estilo': state.estilo.id,
      'idioma': state.idioma,
      'carpeta_out': state.carpetaOut,
    };
    ref.read(repositorioPreferenciasProvider).guardar(prefs);
  }

  void cambiarTemaOscuro(bool valor) {
    state = state.copyWith(temaOscuro: valor);
    _persistir();
  }

  void cambiarEstilo(AppEstilo estilo) {
    state = state.copyWith(estilo: estilo);
    _persistir();
  }

  void cambiarIdioma(String idioma) {
    state = state.copyWith(idioma: idioma);
    _persistir();
  }

  void cambiarCarpetaOut(String carpeta) {
    state = state.copyWith(carpetaOut: carpeta);
    _persistir();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsEstado>(SettingsController.new);
