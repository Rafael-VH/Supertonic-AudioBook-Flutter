import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/barra_progreso.dart';

/// Barra de acción persistente (móvil): progreso + Procesar siempre visibles,
/// Cancelar solo durante la ejecución.
class BarraAccion extends StatelessWidget {
  const BarraAccion({
    super.key,
    required this.estado,
    required this.controller,
    required this.t,
    this.onProcesar,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  /// Callback alternativo al pulsar **Procesar** (p. ej. el gate del modelo
  /// en la pantalla de selección). Si es null se usa `controller.procesar`.
  final VoidCallback? onProcesar;

  @override
  Widget build(BuildContext context) {
    final hayTrabajo = estado.ejecutando || estado.progresoTotal > 0;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hayTrabajo) ...[
                BarraProgreso(
                  actual: estado.progresoActual,
                  total: estado.progresoTotal,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      // Bloqueado durante la ejecución o mientras se prueba
                      // la voz: el motor TTS no soporta síntesis concurrentes.
                      onPressed: (estado.ejecutando || estado.probandoVoz)
                          ? null
                          : (onProcesar ?? () => controller.procesar(t)),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(t.btn_procesar),
                    ),
                  ),
                  if (estado.ejecutando) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.cancelar(t),
                        icon: const Icon(Icons.stop),
                        label: Text(t.btn_cancelar),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
