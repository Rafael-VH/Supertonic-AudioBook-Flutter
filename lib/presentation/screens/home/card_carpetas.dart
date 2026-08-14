import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Card de carpetas de origen y salida (vista de tablet).
class CardCarpetas extends StatelessWidget {
  const CardCarpetas({
    super.key,
    required this.estado,
    required this.habilitado,
    required this.onExaminarIn,
    required this.onExaminarOut,
  });

  final HomeEstado estado;
  final bool habilitado;
  final VoidCallback onExaminarIn;
  final VoidCallback onExaminarOut;

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
              t.carpetas,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ContenidoCarpetas(
              estado: estado,
              habilitado: habilitado,
              onExaminarIn: onExaminarIn,
              onExaminarOut: onExaminarOut,
            ),
          ],
        ),
      ),
    );
  }
}

/// Acordeón de carpetas (móvil), expandido por defecto.
class ExpansionCarpetas extends StatelessWidget {
  const ExpansionCarpetas({
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
    final habilitado = !estado.ejecutando;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          t.carpetas,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _ContenidoCarpetas(
            estado: estado,
            habilitado: habilitado,
            onExaminarIn: controller.examinarCarpetaIn,
            onExaminarOut: controller.examinarCarpetaOut,
          ),
        ],
      ),
    );
  }
}

/// Contenido de las carpetas: origen y salida con su botón Examinar.
class _ContenidoCarpetas extends StatelessWidget {
  const _ContenidoCarpetas({
    required this.estado,
    required this.habilitado,
    required this.onExaminarIn,
    required this.onExaminarOut,
  });

  final HomeEstado estado;
  final bool habilitado;
  final VoidCallback onExaminarIn;
  final VoidCallback onExaminarOut;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.carpeta_origen,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _FilaCarpeta(
          ruta: estado.carpetaIn,
          onExaminar: habilitado ? onExaminarIn : null,
        ),
        const SizedBox(height: 16),
        Text(
          t.salida_audio,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _FilaCarpeta(
          ruta: estado.carpetaOut,
          onExaminar: habilitado ? onExaminarOut : null,
        ),
      ],
    );
  }
}

/// Fila de una carpeta: ruta (ellipsis + tooltip) y botón Examinar.
class _FilaCarpeta extends StatelessWidget {
  const _FilaCarpeta({required this.ruta, required this.onExaminar});

  final String ruta;
  final VoidCallback? onExaminar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: ruta,
            child: Text(
              ruta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onExaminar,
          icon: const Icon(Icons.folder_open),
          label: Text(t.examinar),
        ),
      ],
    );
  }
}
