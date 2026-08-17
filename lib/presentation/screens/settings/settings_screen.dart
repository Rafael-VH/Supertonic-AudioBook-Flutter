import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';
import 'package:supertonic_audiobook/presentation/widgets/acerca_de_section.dart';

/// Idiomas de interfaz con su nombre nativo (plan §6.5 — IDIOMAS).
const _idiomas = <(String, String)>[
  ('es', 'Español'),
  ('en', 'English'),
];

/// Shell de navegación con AppBar para deep links a `/settings`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.ajustes)),
      body: const SettingsBody(),
    );
  }
}

/// Cuerpo reutilizable de ajustes con la card de estado del modelo arriba.
/// Se embebe directamente en el IndexedStack del dashboard (sin Scaffold).
class SettingsBody extends ConsumerWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final ajustes = ref.watch(settingsControllerProvider);
    final controlador = ref.read(settingsControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de estado del modelo (movida desde DashboardScreen)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _CardEstadoModelo(),
        ),
        _SeccionCard(
          titulo: t.tema,
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(t.claro),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text(t.oscuro),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {ajustes.temaOscuro},
            onSelectionChanged: (seleccion) =>
                controlador.cambiarTemaOscuro(seleccion.single),
          ),
        ),
        _SeccionCard(
          titulo: t.estilo,
          child: SegmentedButton<AppEstilo>(
            segments: [
              ButtonSegment(
                value: AppEstilo.material,
                label: Text(t.estilo_material),
              ),
              ButtonSegment(
                value: AppEstilo.neumo,
                label: Text(t.estilo_neumorfismo),
              ),
              ButtonSegment(
                value: AppEstilo.skeuo,
                label: Text(t.estilo_skeuomorfismo),
              ),
            ],
            selected: {ajustes.estilo},
            onSelectionChanged: (seleccion) =>
                controlador.cambiarEstilo(seleccion.single),
          ),
        ),
        _SeccionCard(
          titulo: t.idioma,
          child: SegmentedButton<String>(
            segments: [
              for (final (codigo, nombre) in _idiomas)
                ButtonSegment(value: codigo, label: Text(nombre)),
            ],
            selected: {ajustes.idioma},
            onSelectionChanged: (seleccion) =>
                controlador.cambiarIdioma(seleccion.single),
          ),
        ),
        _SeccionCard(
          titulo: t.settings_carpeta_salida,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings_carpeta_salida_ruta(ajustes.carpetaOut),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final carpeta =
                      await FilePicker.getDirectoryPath();
                  if (carpeta != null) {
                    controlador.cambiarCarpetaOut(carpeta);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: Text(t.settings_carpeta_salida_cambiar),
              ),
            ],
          ),
        ),
        _SeccionCard(
          titulo: t.acerca_de,
          child: const AcercaDeSection(),
        ),
      ],
    );
  }
}

/// Card de estado del modelo: único widget que observa
/// `modeloControllerProvider` (aislado con watch propio).
class _CardEstadoModelo extends ConsumerWidget {
  const _CardEstadoModelo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final estado = ref.watch(modeloControllerProvider);

    final verificando = estado.verificando && !estado.listo;
    final String estadoTexto;
    if (verificando) {
      estadoTexto = t.dashboard_modelo_verificando;
    } else if (estado.listo) {
      estadoTexto = t.dashboard_modelo_descargado;
    } else if (estado.descargando) {
      estadoTexto = t.dashboard_modelo_descargando;
    } else {
      estadoTexto = t.dashboard_modelo_sin_descargar;
    }

    final mostrarCta = !estado.listo && !estado.descargando && !verificando;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    estado.error != null && !estado.descargando
                        ? t.modelo_error(estado.error!)
                        : '${t.dashboard_modelos}: $estadoTexto',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texto.titleMedium,
                  ),
                ),
                if (verificando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (!estado.descargando)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: t.refrescar,
                    onPressed: () =>
                        ref.read(modeloControllerProvider.notifier).verificar(),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
              ],
            ),
            if (estado.descargando) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: estado.progreso),
              const SizedBox(height: 8),
              Text(
                t.modelo_progreso(estado.bytesMb, estado.totalMb),
                style: texto.bodySmall,
              ),
            ],
            if (mostrarCta) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.download),
                label: Text(t.dashboard_modelo_descargar),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () =>
                    context.push(Rutas.modelo, extra: Rutas.dashboard),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: TextStyle(
                    color: primario, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
