import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';

/// Variante del [HomeController] para la pantalla de selección de archivos
/// sueltos: arranca con la lista vacía (los archivos llegan del buscador de
/// archivos, no de la carpeta por defecto).
class SeleccionController extends HomeController {
  @override
  HomeEstado build() {
    final estado = super.build();
    return estado.copyWith(archivos: const []);
  }
}

/// Estado de la pantalla de selección: comparte la lógica de [HomeController]
/// (opciones, procesar, registro) pero con su propia instancia para no pisar
/// el estado del Home.
final seleccionControllerProvider =
    NotifierProvider<SeleccionController, HomeEstado>(SeleccionController.new);
