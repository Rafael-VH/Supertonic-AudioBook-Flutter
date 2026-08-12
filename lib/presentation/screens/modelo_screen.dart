import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Pantalla de arranque que asegura el modelo de voz antes de entrar a Home.
///
/// - Verificando: spinner mientras se comprueba el disco.
/// - Descargando: barra de progreso, MB, archivo actual y botón **Cancelar**.
/// - Error: mensaje y botón para reintentar.
/// - Pendiente: aviso del tamaño y botón **Descargar modelo**.
class ModeloScreen extends ConsumerWidget {
  const ModeloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(modeloControllerProvider);
    final controller = ref.read(modeloControllerProvider.notifier);
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  t.modelo_titulo,
                  style: texto.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t.modelo_aviso,
                  style: texto.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (estado.verificando) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  Text(
                    t.modelo_verificando,
                    style: texto.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ] else if (estado.descargando) ...[
                  LinearProgressIndicator(value: estado.progreso),
                  const SizedBox(height: 8),
                  Text(
                    t.modelo_progreso(estado.bytesMb, estado.totalMb),
                    style: texto.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (estado.archivo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      estado.archivo,
                      style: texto.bodySmall,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: controller.cancelar,
                    icon: const Icon(Icons.stop),
                    label: Text(t.modelo_cancelar),
                  ),
                ] else ...[
                  if (estado.error != null) ...[
                    Text(
                      t.modelo_error(estado.error!),
                      style: texto.bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: controller.descargar,
                    icon: const Icon(Icons.download),
                    label: Text(t.modelo_descargar),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
