import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Estado de error: mensaje localizado + botón reintentar.
class EstadoError extends StatelessWidget {
  const EstadoError({
    super.key,
    required this.error,
    required this.t,
    required this.onReintentar,
  });

  final String error;
  final AppLocalizations t;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              t.biblioteca_error(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: Text(t.refrescar),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: mensaje + acción que lleva a la conversión.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.t, required this.onIrAConvertir});

  final AppLocalizations t;
  final VoidCallback onIrAConvertir;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              t.biblioteca_vacio,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onIrAConvertir,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(t.biblioteca_vacio_accion),
            ),
          ],
        ),
      ),
    );
  }
}
