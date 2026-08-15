import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/acordeon_movil.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_archivos.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_carpetas.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_opciones.dart';
import 'package:supertonic_audiobook/presentation/screens/home/movil/contenido_registro.dart';

/// Móvil: acordeones exclusivos (uno abierto a la vez ocupando el alto) con
/// carpetas expandido por defecto y la acción principal en la barra inferior
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
  /// Índice del acordeón abierto. Solo uno puede estar expandido.
  int _activo = 0;

  Widget _contenidoActivo() {
    final estado = widget.estado;
    final controller = widget.controller;
    final habilitado = !estado.ejecutando;
    return switch (_activo) {
      1 => ContenidoArchivos(
          estado: estado,
          habilitado: habilitado,
          listaExpandida: true,
          onRefrescar: controller.cargarArchivos,
          onTodo: controller.seleccionarTodo,
          onNada: controller.limpiarSeleccion,
          onAlternar: controller.alternarSeleccion,
        ),
      2 => SingleChildScrollView(
          child: ContenidoOpciones(estado: estado, controller: controller),
        ),
      3 => SingleChildScrollView(
          child: ContenidoRegistro(estado: estado, controller: controller),
        ),
      _ => ContenidoCarpetas(
          estado: estado,
          habilitado: habilitado,
          onExaminarIn: controller.examinarCarpetaIn,
          onExaminarOut: controller.examinarCarpetaOut,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoAcordeon(
          titulo: t.carpetas,
          activo: _activo == 0,
          onTap: () => setState(() => _activo = 0),
        ),
        EncabezadoAcordeon(
          titulo: t.archivos_encontrados,
          activo: _activo == 1,
          onTap: () => setState(() => _activo = 1),
        ),
        EncabezadoAcordeon(
          titulo: t.opciones_sintesis,
          activo: _activo == 2,
          onTap: () => setState(() => _activo = 2),
        ),
        EncabezadoAcordeon(
          titulo: t.registro,
          activo: _activo == 3,
          onTap: () => setState(() => _activo = 3),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _contenidoActivo(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
