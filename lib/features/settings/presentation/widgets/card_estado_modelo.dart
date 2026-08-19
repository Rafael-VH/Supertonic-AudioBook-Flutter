import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/modelo/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Card de estado del modelo: único widget que observa
/// `modeloControllerProvider` (aislado con watch propio).
class CardEstadoModelo extends ConsumerWidget {
  const CardEstadoModelo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final estado = ref.watch(modeloControllerProvider);

    final verificando = estado.verificando && !estado.listo;
    final String estadoTexto;
    if (verificando) {
      estadoTexto = t.dashboard_modelo_verificando;
    } else if (estado.listo) {
      estadoTexto = t.dashboard_modelo_descargado;
    } else if (estado.descargando) {
      estadoTexto = t.dashboard_modelo_descargando;
    } else {
      estadoTexto = t.dashboard_modelo_sin_descargar;
    }

    final mostrarCta = !estado.listo && !estado.descargando && !verificando;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    estado.error != null && !estado.descargando
                        ? t.modelo_error(estado.error!)
                        : '${t.dashboard_modelos}: $estadoTexto',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleMedium,
                  ),
                ),
                if (verificando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (!estado.descargando)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: t.refrescar,
                    onPressed: () =>
                        ref.read(modeloControllerProvider.notifier).verificar(),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
              ],
            ),
            if (estado.descargando) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: estado.progreso),
              const SizedBox(height: 8),
              Text(
                t.modelo_progreso(estado.bytesMb, estado.totalMb),
                style: texto.bodySmall,
              ),
            ],
            if (mostrarCta) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.download),
                label: Text(t.dashboard_modelo_descargar),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () =>
                    context.push(Rutas.modelo, extra: Rutas.dashboard),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
