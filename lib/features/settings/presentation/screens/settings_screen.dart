import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:supertonic_audiobook/features/settings/presentation/controllers/settings_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';
import 'package:supertonic_audiobook/features/settings/presentation/widgets/acerca_de_section.dart';
import 'package:supertonic_audiobook/features/settings/presentation/widgets/card_estado_modelo.dart';

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
          child: CardEstadoModelo(),
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
        const _BenchmarkSectionCard(),
        _SeccionCard(
          titulo: t.acerca_de,
          child: const AcercaDeSection(),
        ),
      ],
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

class _BenchmarkSectionCard extends ConsumerWidget {
  const _BenchmarkSectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(benchmarkControllerProvider);
    final resultados = estado.resultados;
    final tieneDatos = resultados.values.any((f) => f != null);
    final avgCharsSeg = tieneDatos
        ? resultados.values
            .whereType<FilaBenchmark>()
            .map((f) => f.charsSeg)
            .reduce((a, b) => a + b) /
            resultados.values.whereType<FilaBenchmark>().length
        : 0.0;

    return _SeccionCard(
      titulo: t.benchmark_titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tieneDatos
                ? t.benchmark_avg_chars_sec(avgCharsSeg.toStringAsFixed(1))
                : t.benchmark_sin_datos,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => context.push(Rutas.benchmark),
            icon: const Icon(Icons.speed),
            label: Text(t.benchmark_btn_ejecutar),
          ),
        ],
      ),
    );
  }
}
