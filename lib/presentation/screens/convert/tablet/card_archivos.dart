import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/movil/contenido_archivos.dart';

/// Card de archivos encontrados con su lista de selección (vista de tablet).
class CardArchivos extends StatelessWidget {
  const CardArchivos({
    super.key,
    required this.estado,
    required this.controller,
    required this.habilitado,
    required this.listaExpandida,
    required this.onRefrescar,
    required this.onTodo,
    required this.onNada,
    required this.onAlternar,
  });

  final HomeEstado estado;
  final HomeController controller;
  final bool habilitado;
  final bool listaExpandida;
  final VoidCallback onRefrescar;
  final VoidCallback onTodo;
  final VoidCallback onNada;
  final ValueChanged<String> onAlternar;

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
              t.archivos_encontrados,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ContenidoArchivos(
              estado: estado,
              controller: controller,
              habilitado: habilitado,
              listaExpandida: listaExpandida,
              onRefrescar: onRefrescar,
              onTodo: onTodo,
              onNada: onNada,
              onAlternar: onAlternar,
            ),
          ],
        ),
      ),
    );
  }
}
