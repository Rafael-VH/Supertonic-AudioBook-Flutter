import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/paleta.dart';
import 'providers.dart';

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

/// Ajustes de la interfaz. Los valores iniciales se cargan del repositorio
/// inyectado (claves de §6.3) y cada cambio se persiste de inmediato.
class SettingsController extends Notifier<SettingsEstado> {
  @override
  SettingsEstado build() {
    final preferencias = ref.watch(repositorioPreferenciasProvider).cargar();
    return SettingsEstado(
      temaOscuro: preferencias['tema_oscuro'] as bool? ?? false,
      estilo: AppEstilo.desdeId(preferencias['estilo'] as String?),
      idioma: preferencias['idioma'] as String? ?? 'es',
    );
  }

  void _persistir() {
    ref.read(repositorioPreferenciasProvider).guardar({
      'tema_oscuro': state.temaOscuro,
      'estilo': state.estilo.id,
      'idioma': state.idioma,
    });
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
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsEstado>(SettingsController.new);
