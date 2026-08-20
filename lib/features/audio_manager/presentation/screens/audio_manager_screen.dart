import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supertonic_audiobook/features/audio_manager/domain/entities/audio_pendiente.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';

/// Pantalla de audios pendientes: muestra los WAVs generados recién y permite
/// renombrar, elegir carpeta destino y guardar (individual o todos).
class AudioManagerScreen extends ConsumerStatefulWidget {
  const AudioManagerScreen({super.key, required this.pendientes});

  final List<AudioPendiente> pendientes;

  @override
  ConsumerState<AudioManagerScreen> createState() =>
      _AudioManagerScreenState();
}

class _AudioManagerScreenState extends ConsumerState<AudioManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Inject pendientes into the controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(audioManagerControllerProvider.notifier)
          .setPendientes(List.of(widget.pendientes));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.audio_manager_title)),
      body: const _AudioManagerBody(),
      bottomNavigationBar: const _SaveAllBar(),
    );
  }
}

/// Body del AudioManager: lista o estado vacío.
class _AudioManagerBody extends ConsumerWidget {
  const _AudioManagerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(audioManagerControllerProvider);

    if (estado.vacio) {
      return _EmptyState(t: t);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: estado.pendientes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _AudioTile(pendiente: estado.pendientes[i], index: i),
    );
  }
}

/// Estado vacío cuando no hay audios pendientes.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audio_file_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              t.audio_manager_empty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile individual de un audio pendiente.
class _AudioTile extends ConsumerStatefulWidget {
  const _AudioTile({required this.pendiente, required this.index});

  final AudioPendiente pendiente;
  final int index;

  @override
  ConsumerState<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends ConsumerState<_AudioTile> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.audio_file_outlined),
        title: Text(widget.pendiente.displayName),
        subtitle: _MetadataRow(pendiente: widget.pendiente, t: t),
        trailing: PopupMenuButton<String>(
          onSelected: _onSelected,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'folder',
              child: Text(t.audio_manager_choose_folder),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Text(t.audio_manager_rename),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(t.audio_manager_delete),
            ),
          ],
        ),
      ),
    );
  }

  void _onSelected(String value) async {
    final t = AppLocalizations.of(context)!;
    final controller = ref.read(audioManagerControllerProvider.notifier);

    switch (value) {
      case 'folder':
        final messenger = ScaffoldMessenger.of(context);
        final carpeta = await FilePicker.getDirectoryPath();
        if (carpeta != null && mounted) {
          await controller.guardarUno(
            widget.pendiente,
            carpetaDestino: carpeta,
            nombreArchivo:
                '${widget.pendiente.displayName}.${widget.pendiente.format}',
          );
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(t.audio_manager_saved)),
            );
          }
        }
      case 'rename':
        if (!mounted) return;
        final nombre = await _showRenameDialog(context, t);
        if (nombre != null && nombre.isNotEmpty) {
          controller.actualizarNombre(widget.index, nombre);
        }
      case 'delete':
        controller.eliminar(widget.index);
    }
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    AppLocalizations t,
  ) {
    final controller = TextEditingController(text: widget.pendiente.displayName);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.audio_manager_rename_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.audio_manager_name,
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.audio_manager_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(t.audio_manager_save),
          ),
        ],
      ),
    );
  }
}

/// Fila de metadatos: formato · duración · tamaño.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.pendiente, required this.t});

  final AudioPendiente pendiente;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final min = (pendiente.durationSec ~/ 60);
    final seg = (pendiente.durationSec % 60).round();
    final duracion = t.tiempo_min_seg(min, seg);
    final tamano = _formatBytes(pendiente.fileSizeBytes);

    return Text(
      '${pendiente.format.toUpperCase()} · $duracion · $tamano',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Barra inferior con botón "Guardar Todos".
class _SaveAllBar extends ConsumerWidget {
  const _SaveAllBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(audioManagerControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                estado.vacio || estado.guardando ? null : () => _saveAll(context, ref),
            icon: estado.guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(t.audio_manager_save_all),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAll(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;
    final carpeta = await FilePicker.getDirectoryPath();
    if (carpeta == null || !context.mounted) return;

    final controller = ref.read(audioManagerControllerProvider.notifier);
    await controller.guardarTodos(carpeta);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.audio_manager_saved_all)),
      );
    }
  }
}
