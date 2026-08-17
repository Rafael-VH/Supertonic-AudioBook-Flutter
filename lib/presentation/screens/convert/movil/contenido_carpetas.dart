
import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Contenido de las carpetas: origen y salida con su botón Examinar.
class ContenidoCarpetas extends StatelessWidget {
  const ContenidoCarpetas({
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
