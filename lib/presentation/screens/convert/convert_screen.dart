import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/movil/cuerpo_apilado.dart';
import 'package:supertonic_audiobook/presentation/screens/convert/tablet/cuerpo_lado_alado.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/widgets/barra_accion.dart';

/// Umbral de ancho para mostrar los paneles lado a lado (Material 6.2, responsive).
const int umbralAncho = 900;

/// Pantalla principal: carpetas, archivos `.md`, opciones de síntesis,
/// registro y la acción de procesar.
///
/// En tablet (>= [umbralAncho]) los paneles van lado a lado con scroll
/// propio; en móvil se apilan con la lista de archivos como protagonista y
/// una barra de acción inferior persistente (plan de mejora de interfaz).
class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ventana_titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.ajustes,
            onPressed: () => context.push(Rutas.settings),
          ),
        ],
      ),
      body: const ConvertBody(),
    );
  }
}

/// Cuerpo reutilizable de la pantalla Home (sin Scaffold propio).
/// Se usa tanto en [ConvertScreen] como embebido en el [DashboardScreen] con
/// BottomNavigationBar.
class ConvertBody extends ConsumerWidget {
  const ConvertBody({super.key});

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

    if (ladoAlado) {
      return CuerpoLadoAlado(estado: estado, controller: controller, t: t);
    }

    return Column(
      children: [
        Expanded(
          child: CuerpoApilado(estado: estado, controller: controller, t: t),
        ),
        BarraAccion(estado: estado, controller: controller, t: t),
      ],
    );
  }
}
