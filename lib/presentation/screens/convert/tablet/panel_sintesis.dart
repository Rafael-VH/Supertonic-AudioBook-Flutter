import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/tablet/card_opciones.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/tablet/card_registro.dart';

/// Panel de síntesis: opciones y registro (vista de tablet).
class PanelSintesis extends StatelessWidget {
  const PanelSintesis({
    super.key,
    required this.estado,
    required this.controller,
    required this.t,
    required this.conBotones,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;
  final bool conBotones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardOpciones(estado: estado, controller: controller),
          const SizedBox(height: 16),
          CardRegistro(
            estado: estado,
            controller: controller,
            conBotones: conBotones,
          ),
        ],
      ),
    );
  }
}
