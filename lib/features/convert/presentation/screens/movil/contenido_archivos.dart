import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/features/convert/domain/entities/selection_mode.dart';
import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/features/convert/presentation/widgets/archivo_tile.dart';

/// Contenido de la card de archivos: origen, acciones, conteo, ayuda y lista.
class ContenidoArchivos extends StatelessWidget {
  const ContenidoArchivos({
    super.key,
    required this.estado,
    required this.controller,
    required this.habilitado,
    required this.listaExpandida,
    required this.onRefrescar,
    required this.onTodo,
    required this.onNada,
    required this.onAlternar,
  });

  final HomeEstado estado;
  final HomeController controller;
  final bool habilitado;
  final bool listaExpandida;
  final VoidCallback onRefrescar;
  final VoidCallback onTodo;
  final VoidCallback onNada;
  final ValueChanged<String> onAlternar;

  /// Abre el selector de archivos `.md` y los agrega a la lista existente.
  Future<void> _agregarArchivos(BuildContext context) async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'],
      allowMultiple: true,
    );
    if (resultado == null || context.mounted == false) return;
    final archivos = [
      for (final f in resultado.files)
        if (f.path != null) Archivo(f.path!),
    ];
    if (archivos.isNotEmpty) {
      controller.agregarArchivosExternos(archivos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sel = estado.seleccion.length;
    final total = estado.archivos.length;
    final esModoArchivos = estado.modoSeleccion == SelectionMode.archivos;
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
        // Selector de origen: solo en modo carpeta
        if (!esModoArchivos) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: habilitado ? () => controller.examinarCarpetaIn() : null,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(t.btn_carpeta),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: habilitado ? () => _agregarArchivos(context) : null,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: Text(t.btn_archivos),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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
            if (!esModoArchivos)
              IconButton(
                tooltip: t.refrescar,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                onPressed: habilitado ? onRefrescar : null,
              ),
          ],
        ),
        Text(etiquetaConteo, style: Theme.of(context).textTheme.bodySmall),
        if (!esModoArchivos)
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
