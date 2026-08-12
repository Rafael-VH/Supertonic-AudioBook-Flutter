import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/widgets/barra_progreso.dart';

/// Card de registro: log, estado, progreso y (desktop) botones de acción.
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
                  : SingleChildScrollView(
                      reverse: true,
                      child: SelectableText(
                        estado.lineasLog.reversed.join('\n'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
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
            if (conBotones) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: estado.ejecutando
                          ? null
                          : () => controller.procesar(t),
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

/// Registro colapsable (móvil), autoexpandido durante la ejecución.
class ExpansionRegistro extends StatelessWidget {
  const ExpansionRegistro({
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
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ExpansionTile(
        title: Text(t.registro, style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [_ContenidoRegistro(estado: estado, controller: controller)],
      ),
    );
  }
}

/// Contenido del registro: log, estado y progreso.
class _ContenidoRegistro extends StatelessWidget {
  const _ContenidoRegistro({required this.estado, required this.controller});

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
