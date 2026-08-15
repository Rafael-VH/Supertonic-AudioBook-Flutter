import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/tablet/card_archivos.dart';
import 'package:supertonic_audiobook/presentation/screens/home/tablet/card_carpetas.dart';

/// Panel de entrada: carpetas de origen/salida y lista de archivos.
class PanelEntrada extends StatelessWidget {
  const PanelEntrada({
    super.key,
    required this.estado,
    required this.controller,
    required this.t,
    required this.listaExpandida,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;
  final bool listaExpandida;

  @override
  Widget build(BuildContext context) {
    final habilitado = !estado.ejecutando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listaExpandida)
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: CardCarpetas(
                estado: estado,
                habilitado: habilitado,
                onExaminarIn: controller.examinarCarpetaIn,
                onExaminarOut: controller.examinarCarpetaOut,
              ),
            ),
          )
        else
          CardCarpetas(
            estado: estado,
            habilitado: habilitado,
            onExaminarIn: controller.examinarCarpetaIn,
            onExaminarOut: controller.examinarCarpetaOut,
          ),
        const SizedBox(height: 16),
        if (listaExpandida)
          Expanded(
            child: CardArchivos(
              estado: estado,
              habilitado: habilitado,
              listaExpandida: listaExpandida,
              onRefrescar: controller.cargarArchivos,
              onTodo: controller.seleccionarTodo,
              onNada: controller.limpiarSeleccion,
              onAlternar: controller.alternarSeleccion,
            ),
          )
        else
          CardArchivos(
            estado: estado,
            habilitado: habilitado,
            listaExpandida: listaExpandida,
            onRefrescar: controller.cargarArchivos,
            onTodo: controller.seleccionarTodo,
            onNada: controller.limpiarSeleccion,
            onAlternar: controller.alternarSeleccion,
          ),
      ],
    );
  }
}
