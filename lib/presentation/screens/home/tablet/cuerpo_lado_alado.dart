import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/tablet/panel_entrada.dart';
import 'package:supertonic_audiobook/presentation/screens/home/tablet/panel_sintesis.dart';

/// Tablet: dos paneles lado a lado, cada uno con sus cards.
class CuerpoLadoAlado extends StatelessWidget {
  const CuerpoLadoAlado({
    super.key,
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PanelEntrada(
              estado: estado,
              controller: controller,
              t: t,
              listaExpandida: false,
            ),
          ),
          Expanded(
            child: PanelSintesis(
              estado: estado,
              controller: controller,
              t: t,
              conBotones: true,
            ),
          ),
        ],
      ),
    );
  }
}
