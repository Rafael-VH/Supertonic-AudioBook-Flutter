import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Sección "Archivos Seleccionados" en modo File.
/// Muestra los archivos elegidos desde el HomeScreen con opción de agregar más
/// o quitar individuales.
class ContenidoArchivosSeleccionados extends StatefulWidget {
  const ContenidoArchivosSeleccionados({
    super.key,
    required this.t,
    required this.estado,
    required this.controller,
  });

  final AppLocalizations t;
  final HomeEstado estado;
  final HomeController controller;

  @override
  State<ContenidoArchivosSeleccionados> createState() =>
      _ContenidoArchivosSeleccionadosState();
}

class _ContenidoArchivosSeleccionadosState
    extends State<ContenidoArchivosSeleccionados> {
  bool _abriendo = false;

  Future<void> _agregarMas() async {
    if (_abriendo) return;
    setState(() => _abriendo = true);
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        allowMultiple: true,
      );
      if (!mounted) return;
      final archivos = [
        for (final f in resultado?.files ?? const <PlatformFile>[])
          if (f.path != null) Archivo(f.path!),
      ];
      if (archivos.isNotEmpty) {
        widget.controller.agregarArchivosExternos(archivos);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.t.seleccion_error_picker),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final archivos = widget.estado.archivos;

    if (archivos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            _abriendo ? t.seleccion_buscando : t.seleccion_sin_archivos,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _abriendo ? null : _agregarMas,
            icon: const Icon(Icons.folder_open),
            label: Text(t.seleccion_elegir),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.conteo_archivos(archivos.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final a in archivos)
          ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(
              a.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              a.ruta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: t.seleccion_quitar,
              icon: const Icon(Icons.close),
              onPressed: () => widget.controller.quitarArchivoExterno(a.ruta),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _abriendo ? null : _agregarMas,
          icon: const Icon(Icons.add),
          label: Text(t.seleccion_agregar),
        ),
      ],
    );
  }
}
