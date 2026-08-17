import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/acordeon_movil.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_archivos.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_carpetas.dart';
import 'package:supertonic_audiobook/presentation/widgets/contenido_opciones.dart';
import 'package:supertonic_audiobook/presentation/widgets/contenido_registro.dart';

/// Móvil: acordeones que se empujan entre sí — al expandir uno, el contenido
/// se muestra debajo del encabezado y empuja las demás secciones hacia abajo.
/// Carpetas expandido por defecto y la acción principal en la barra inferior
/// persistente.
class CuerpoApilado extends StatefulWidget {
  const CuerpoApilado({
    super.key,
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  State<CuerpoApilado> createState() => _CuerpoApiladoState();
}

class _CuerpoApiladoState extends State<CuerpoApilado> {
  /// Índice del acordeón abierto. -1 = ninguno abierto.
  int _activo = 0;

  Widget _contenidoSeccion(int index) {
    final estado = widget.estado;
    final controller = widget.controller;
    final habilitado = !estado.ejecutando;

    return switch (index) {
      1 => ContenidoArchivos(
          key: const ValueKey(1),
          estado: estado,
          controller: controller,
          habilitado: habilitado,
          listaExpandida: false, // false dentro de SingleChildScrollView
          onRefrescar: controller.cargarArchivos,
          onTodo: controller.seleccionarTodo,
          onNada: controller.limpiarSeleccion,
          onAlternar: controller.alternarSeleccion,
        ),
      2 => SingleChildScrollView(
          key: const ValueKey(2),
          child: ContenidoOpciones(estado: estado, controller: controller),
        ),
      3 => SingleChildScrollView(
          key: const ValueKey(3),
          child: ContenidoRegistro(estado: estado, controller: controller),
        ),
      _ => ContenidoCarpetas(
          key: const ValueKey(0),
          estado: estado,
          habilitado: habilitado,
          onExaminarIn: controller.examinarCarpetaIn,
          onExaminarOut: controller.examinarCarpetaOut,
        ),
    };
  }

  /// Construye una sección de acordeón (encabezado + contenido condicional).
  Widget _seccionAcordeon(int index, String titulo) {
    final estaAbierto = _activo == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EncabezadoAcordeon(
          titulo: titulo,
          activo: estaAbierto,
          onTap: () => setState(() => _activo = estaAbierto ? -1 : index),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: estaAbierto
              ? Padding(
                  key: ValueKey(index),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _contenidoSeccion(index),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey(-1)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _seccionAcordeon(0, t.carpetas),
          _seccionAcordeon(1, t.archivos_encontrados),
          _seccionAcordeon(2, t.opciones_sintesis),
          _seccionAcordeon(3, t.registro),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
