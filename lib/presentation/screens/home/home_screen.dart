import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/card_registro.dart';
import 'package:supertonic_audiobook/presentation/screens/home/panel_entrada.dart';
import 'package:supertonic_audiobook/presentation/screens/home/panel_sintesis.dart';
import 'package:supertonic_audiobook/presentation/screens/settings_screen.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/widgets/barra_progreso.dart';

/// Umbral de ancho para mostrar los paneles lado a lado (Material 6.2, responsive).
const int umbralAncho = 900;
/// Altura mínima del área del panel móvil para que la lista llene el alto;
/// por debajo, el cuerpo apilado degrada a scroll para no desbordar.
/// Escala con el texto del sistema: las cards crecen con textScale alto.
double _alturaMinimaPanelApilado(BuildContext context) =>
    400 * MediaQuery.textScalerOf(context).scale(1);

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
          ? _CuerpoLadoAlado(estado: estado, controller: controller, t: t)
          : _CuerpoApilado(estado: estado, controller: controller, t: t),
      bottomNavigationBar: ladoAlado
          ? null
          : _BarraAccion(
              estado: estado,
              controller: controller,
              t: t,
            ),
    );
  }
}

/// Tablet: dos paneles lado a lado, cada uno con sus cards.
class _CuerpoLadoAlado extends StatelessWidget {
  const _CuerpoLadoAlado({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PanelEntrada(
              estado: estado,
              controller: controller,
              t: t,
              listaExpandida: false,
            ),
          ),
          Expanded(
            child: PanelSintesis(
              estado: estado,
              controller: controller,
              t: t,
              conBotones: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Móvil: la lista de archivos llena el alto; opciones y registro quedan
/// colapsados y la acción principal vive en la barra inferior.
class _CuerpoApilado extends StatelessWidget {
  const _CuerpoApilado({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight >= _alturaMinimaPanelApilado(context)) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: PanelEntrada(
                    estado: estado,
                    controller: controller,
                    t: t,
                    listaExpandida: true,
                  ),
                );
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: PanelEntrada(
                    estado: estado,
                    controller: controller,
                    t: t,
                    listaExpandida: false,
                  ),
                ),
              );
            },
          ),
        ),
        ExpansionOpciones(estado: estado, controller: controller, t: t),
        ExpansionRegistro(estado: estado, controller: controller, t: t),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Barra de acción persistente (móvil): progreso + Procesar siempre visibles,
/// Cancelar solo durante la ejecución.
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

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
                      onPressed: estado.ejecutando
                          ? null
                          : () => controller.procesar(t),
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
