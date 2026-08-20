import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/barra_progreso.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/vista_log.dart';

/// Card de registro: log, estado, progreso y (vista de tablet) botones de acción.
class CardRegistro extends StatelessWidget {
  const CardRegistro({
    super.key,
    required this.estado,
    required this.controller,
    required this.conBotones,
  });

  final HomeEstado estado;
  final HomeController controller;
  final bool conBotones;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.registro, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: estado.lineasLog.isEmpty
                  ? const SizedBox.shrink()
                  : VistaLog(lineas: estado.lineasLog),
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
            if (conBotones) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      // Bloqueado durante la ejecución o mientras se prueba
                      // la voz: el motor TTS no soporta síntesis concurrentes.
                      onPressed: (estado.ejecutando || estado.probandoVoz)
                          ? null
                          : () => controller.procesar(t, context: context),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(t.btn_procesar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: estado.ejecutando
                          ? () => controller.cancelar(t)
                          : null,
                      icon: const Icon(Icons.stop),
                      label: Text(t.btn_cancelar),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
