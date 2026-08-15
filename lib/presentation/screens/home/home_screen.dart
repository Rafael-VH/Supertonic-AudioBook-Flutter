import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/barra_accion.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/cuerpo_apilado.dart';
import 'package:supertonic_audiobook/presentation/screens/home/tablet/cuerpo_lado_alado.dart';
import 'package:supertonic_audiobook/presentation/screens/settings/settings_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

/// Umbral de ancho para mostrar los paneles lado a lado (Material 6.2, responsive).
const int umbralAncho = 900;

/// Pantalla principal: carpetas, archivos `.md`, opciones de síntesis,
/// registro y la acción de procesar.
///
/// En tablet (>= [umbralAncho]) los paneles van lado a lado con scroll
/// propio; en móvil se apilan con la lista de archivos como protagonista y
/// una barra de acción inferior persistente (plan de mejora de interfaz).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final ladoAlado = MediaQuery.sizeOf(context).width >= umbralAncho;

    ref.listen(homeControllerProvider.select((s) => s.snackbar), (prev, msg) {
      if (msg == null) return;
      final paleta = PaletaExt.of(context)?.paleta;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg.texto),
          behavior: ladoAlado
              ? SnackBarBehavior.floating
              : SnackBarBehavior.fixed,
          backgroundColor: msg.esError
              ? (paleta?.error ?? Theme.of(context).colorScheme.error)
              : null,
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ventana_titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.ajustes,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ladoAlado
          ? CuerpoLadoAlado(estado: estado, controller: controller, t: t)
          : CuerpoApilado(estado: estado, controller: controller, t: t),
      bottomNavigationBar: ladoAlado
          ? null
          : BarraAccion(estado: estado, controller: controller, t: t),
    );
  }
}
