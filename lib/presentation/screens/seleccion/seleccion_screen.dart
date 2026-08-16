import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/seleccion_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/widgets/barra_accion.dart';
import 'package:supertonic_audiobook/presentation/widgets/contenido_opciones.dart';
import 'package:supertonic_audiobook/presentation/widgets/contenido_registro.dart';

/// Pantalla para procesar archivos `.md` sueltos (elegidos uno a uno con el
/// buscador de archivos, sin carpeta de entrada). Reutiliza la lógica y el
/// registro de la pantalla Home con su propia instancia del controller.
class SeleccionScreen extends ConsumerStatefulWidget {
  const SeleccionScreen({super.key});

  @override
  ConsumerState<SeleccionScreen> createState() => _SeleccionScreenState();
}

class _SeleccionScreenState extends ConsumerState<SeleccionScreen> {
  /// El buscador de archivos está abierto (evita abrirlo dos veces).
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _elegirArchivos());
  }

  /// Abre el buscador de archivos y carga los `.md` elegidos.
  Future<void> _elegirArchivos() async {
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
        ref
            .read(seleccionControllerProvider.notifier)
            .agregarArchivosExternos(archivos);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.seleccion_error_picker),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  /// Gate del modelo en esta pantalla (opción del usuario): sin redirect, solo
  /// un aviso al procesar si el modelo no está listo.
  Future<void> _procesarConGate(bool modeloListo) async {
    final t = AppLocalizations.of(context)!;
    if (!modeloListo) {
      final ir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.seleccion_modelo_aviso),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cerrar),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.seleccion_ir_modelo),
            ),
          ],
        ),
      );
      if (ir == true && mounted) {
        context.push(Rutas.modelo, extra: Rutas.seleccion);
      }
      return;
    }
    ref.read(seleccionControllerProvider.notifier).procesar(t);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(seleccionControllerProvider);
    final controller = ref.read(seleccionControllerProvider.notifier);
    final modeloListo = ref.watch(modeloControllerProvider.select((s) => s.listo));

    ref.listen(seleccionControllerProvider.select((s) => s.snackbar), (
      previo,
      msg,
    ) {
      if (msg == null) return;
      final paleta = PaletaExt.of(context)?.paleta;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg.texto),
          backgroundColor: msg.esError
              ? (paleta?.error ?? Theme.of(context).colorScheme.error)
              : null,
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.seleccion_titulo)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _ListaArchivos(
              estado: estado,
              controller: controller,
              abriendo: _abriendo,
              onElegir: _elegirArchivos,
            ),
            const SizedBox(height: 16),
            Text(t.opciones_sintesis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ContenidoOpciones(estado: estado, controller: controller),
            const SizedBox(height: 16),
            Text(t.registro, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ContenidoRegistro(estado: estado, controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: BarraAccion(
        estado: estado,
        controller: controller,
        t: t,
        onProcesar: () => _procesarConGate(modeloListo),
      ),
    );
  }
}

/// Lista de archivos elegidos con el buscador, o el estado vacío con el botón
/// para abrirlo.
class _ListaArchivos extends StatelessWidget {
  const _ListaArchivos({
    required this.estado,
    required this.controller,
    required this.abriendo,
    required this.onElegir,
  });

  final HomeEstado estado;
  final SeleccionController controller;
  final bool abriendo;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (estado.archivos.isEmpty) {
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
            abriendo ? t.seleccion_buscando : t.seleccion_sin_archivos,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: abriendo ? null : onElegir,
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
          t.conteo_archivos(estado.archivos.length),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final a in estado.archivos)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(a.nombre),
                  subtitle: Text(a.ruta, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: t.seleccion_quitar,
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.quitarArchivoExterno(a.ruta),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: abriendo ? null : onElegir,
          icon: const Icon(Icons.add),
          label: Text(t.seleccion_agregar),
        ),
      ],
    );
  }
}
