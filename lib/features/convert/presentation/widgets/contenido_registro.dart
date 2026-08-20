
import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/vista_log.dart';

/// Contenido del registro: log y estado.
/// La barra de progreso vive en [BarraAccion] (barra inferior persistente).
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
          height: 420,
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
      ],
    );
  }
}
