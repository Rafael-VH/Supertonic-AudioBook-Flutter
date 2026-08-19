import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/shared/domain/entities/archivo.dart';
import 'package:supertonic_audiobook/features/convert/domain/entities/selection_mode.dart';
import 'package:supertonic_audiobook/features/convert/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/features/home/presentation/widgets/function_card.dart';

/// Hub principal que muestra las funciones disponibles de la app.
/// Se embebe en el tab 0 del [DashboardScreen].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _mostrarOpcionesConversion(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.home_seleccionar_fuente,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(t.home_seleccionar_carpeta),
                subtitle: Text(t.home_seleccionar_carpeta_desc),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final carpeta = await FilePicker.getDirectoryPath();
                  if (carpeta != null && context.mounted) {
                    ref
                        .read(homeControllerProvider.notifier)
                        .setCarpetaIn(carpeta);
                    context.push(Rutas.home);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(t.home_seleccionar_archivos),
                subtitle: Text(t.home_seleccionar_archivos_desc),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final resultado = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['md'],
                    allowMultiple: true,
                  );
                  if (resultado != null && context.mounted) {
                    final archivos = [
                      for (final f in resultado.files)
                        Archivo(f.path!),
                    ];
                    ref.read(homeControllerProvider.notifier).setModo(
                          SelectionMode.archivos,
                          archivosExternos: archivos,
                        );
                    context.push(Rutas.home);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.dashboard_bienvenida,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              t.dashboard_bienvenida_sub,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FunctionCard(
              icon: Icons.audiotrack_outlined,
              selectedIcon: Icons.audiotrack,
              title: t.dashboard_procesar,
              description: t.dashboard_procesar_desc,
              onTap: () => _mostrarOpcionesConversion(context, ref),
            ),
            const SizedBox(height: 12),
            FunctionCard(
              icon: Icons.edit_outlined,
              selectedIcon: Icons.edit,
              title: t.home_editor_metadata,
              description: t.home_editor_metadata_desc,
              onTap: () => context.push(Rutas.editorMetadata),
            ),
            const SizedBox(height: 12),
            FunctionCard(
              icon: Icons.record_voice_over_outlined,
              selectedIcon: Icons.record_voice_over,
              title: t.home_editor_voz,
              description: t.home_editor_voz_desc,
              enabled: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
