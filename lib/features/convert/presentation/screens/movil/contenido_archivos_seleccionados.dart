import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Placeholder para la sección "Archivos Seleccionados" en modo File.
/// Muestra los archivos que el usuario seleccionó desde el HomeScreen.
class ContenidoArchivosSeleccionados extends StatelessWidget {
  const ContenidoArchivosSeleccionados({
    super.key,
    required this.t,
  });

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          t.archivos_seleccionados,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
