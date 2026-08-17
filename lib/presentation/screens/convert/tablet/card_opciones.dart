import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/widgets/contenido_opciones.dart';

/// Card de opciones de síntesis (vista de tablet).
class CardOpciones extends StatelessWidget {
  const CardOpciones({
    super.key,
    required this.estado,
    required this.controller,
  });

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.opciones_sintesis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ContenidoOpciones(estado: estado, controller: controller),
          ],
        ),
      ),
    );
  }
}
