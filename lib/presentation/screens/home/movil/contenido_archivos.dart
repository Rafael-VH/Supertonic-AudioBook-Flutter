import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/widgets/archivo_tile.dart';

/// Contenido de la card de archivos: acciones, conteo, ayuda y lista.
class ContenidoArchivos extends StatelessWidget {
  const ContenidoArchivos({
    super.key,
    required this.estado,
    required this.habilitado,
    required this.listaExpandida,
    required this.onRefrescar,
    required this.onTodo,
    required this.onNada,
    required this.onAlternar,
  });

  final HomeEstado estado;
  final bool habilitado;
  final bool listaExpandida;
  final VoidCallback onRefrescar;
  final VoidCallback onTodo;
  final VoidCallback onNada;
  final ValueChanged<String> onAlternar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sel = estado.seleccion.length;
    final total = estado.archivos.length;
    final etiquetaConteo = sel > 0
        ? t.conteo_seleccionados(sel, total)
        : total > 0
        ? t.conteo_archivos(total)
        : t.conteo_sin;

    final lista = estado.archivos.isEmpty
        ? Center(
            child: Text(
              t.conteo_sin,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        : ListView.builder(
            itemCount: estado.archivos.length,
            itemBuilder: (context, i) {
              final archivo = estado.archivos[i];
              return ArchivoTile(
                archivo: archivo,
                seleccionado: estado.seleccion.contains(archivo.ruta),
                habilitado: habilitado,
                onChanged: (_) => onAlternar(archivo.ruta),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              tooltip: t.todo,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.done_all),
              onPressed: habilitado ? onTodo : null,
            ),
            IconButton(
              tooltip: t.nada,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.deselect),
              onPressed: habilitado ? onNada : null,
            ),
            IconButton(
              tooltip: t.refrescar,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh),
              onPressed: habilitado ? onRefrescar : null,
            ),
          ],
        ),
        Text(etiquetaConteo, style: Theme.of(context).textTheme.bodySmall),
        Text(
          t.ayuda_seleccion,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (listaExpandida)
          Expanded(child: lista)
        else
          SizedBox(height: 280, child: lista),
      ],
    );
  }
}
