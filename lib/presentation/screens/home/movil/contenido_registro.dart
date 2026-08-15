
import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/widgets/barra_progreso.dart';

/// Contenido del registro: log, estado y progreso.
class ContenidoRegistro extends StatelessWidget {
  const ContenidoRegistro({
    super.key,
    required this.estado,
    required this.controller,
  });

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: estado.lineasLog.isEmpty
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    estado.lineasLog.reversed.join('\n'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          estado.estado.isEmpty ? t.estado_listo : estado.estado,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        BarraProgreso(
          actual: estado.progresoActual,
          total: estado.progresoTotal,
        ),
      ],
    );
  }
}
