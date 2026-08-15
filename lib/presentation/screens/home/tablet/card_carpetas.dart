import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_carpetas.dart';

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
            ContenidoCarpetas(
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
