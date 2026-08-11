import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/paleta.dart';

/// Estado de los ajustes de interfaz (plan §6.3, claves exactas).
class SettingsEstado {
  const SettingsEstado({
    required this.temaOscuro,
    required this.estilo,
    required this.idioma,
  });

  final bool temaOscuro;
  final AppEstilo estilo;
  final String idioma;

  SettingsEstado copyWith({bool? temaOscuro, AppEstilo? estilo, String? idioma}) {
    return SettingsEstado(
      temaOscuro: temaOscuro ?? this.temaOscuro,
      estilo: estilo ?? this.estilo,
      idioma: idioma ?? this.idioma,
    );
  }
}

/// Ajustes de la interfaz. Los valores iniciales son los defaults de §6.3;
/// la carga/persistencia se conecta en la composición (main.dart).
class SettingsController extends Notifier<SettingsEstado> {
  @override
  SettingsEstado build() {
    return const SettingsEstado(
      temaOscuro: false,
      estilo: AppEstilo.material,
      idioma: 'es',
    );
  }

  void cambiarTemaOscuro(bool valor) {
    state = state.copyWith(temaOscuro: valor);
  }

  void cambiarEstilo(AppEstilo estilo) {
    state = state.copyWith(estilo: estilo);
  }

  void cambiarIdioma(String idioma) {
    state = state.copyWith(idioma: idioma);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsEstado>(SettingsController.new);
