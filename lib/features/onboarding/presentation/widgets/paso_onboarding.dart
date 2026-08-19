import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Paso genérico del onboarding: icono + título + descripción centrados.
class PasoOnboarding extends StatelessWidget {
  const PasoOnboarding({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 48, color: colores.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            titulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            descripcion,
            style: texto.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Paso final del onboarding: selección de carpeta de salida.
class PasoOnboardingCarpeta extends StatelessWidget {
  const PasoOnboardingCarpeta({
    super.key,
    required this.ruta,
    required this.onElegir,
  });

  final String? ruta;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: colores.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            t.onboarding_paso5_titulo,
            style: texto.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            t.onboarding_paso5_descripcion,
            style: texto.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: onElegir,
            icon: const Icon(Icons.folder_open),
            label: Text(t.onboarding_paso5_examinar),
          ),
          if (ruta != null) ...[
            const SizedBox(height: 12),
            Text(
              t.onboarding_paso5_ruta(ruta!),
              style: texto.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
