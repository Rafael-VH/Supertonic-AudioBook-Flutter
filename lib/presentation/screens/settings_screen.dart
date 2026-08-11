import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/settings_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/paleta.dart';
import '../widgets/acerca_de_section.dart';

/// Idiomas de interfaz con su nombre nativo (plan §6.5 — IDIOMAS).
const _idiomas = <(String, String)>[
  ('es', 'Español'),
  ('en', 'English'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final ajustes = ref.watch(settingsControllerProvider);
    final controlador = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t?.ajustes ?? 'Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeccionCard(
            titulo: t?.tema ?? 'Tema',
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(t?.claro ?? 'Claro'),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(t?.oscuro ?? 'Oscuro'),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {ajustes.temaOscuro},
              onSelectionChanged: (seleccion) =>
                  controlador.cambiarTemaOscuro(seleccion.single),
            ),
          ),
          _SeccionCard(
            titulo: t?.estilo ?? 'Estilo',
            child: SegmentedButton<AppEstilo>(
              segments: [
                ButtonSegment(
                  value: AppEstilo.material,
                  label: Text(t?.estilo_material ?? 'Material'),
                ),
                ButtonSegment(
                  value: AppEstilo.neumo,
                  label: Text(t?.estilo_neumorfismo ?? 'Neumorfismo'),
                ),
                ButtonSegment(
                  value: AppEstilo.skeuo,
                  label: Text(t?.estilo_skeuomorfismo ?? 'Skeuomorfismo'),
                ),
              ],
              selected: {ajustes.estilo},
              onSelectionChanged: (seleccion) =>
                  controlador.cambiarEstilo(seleccion.single),
            ),
          ),
          _SeccionCard(
            titulo: t?.idioma ?? 'Idioma',
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
            titulo: t?.acerca_de ?? 'Acerca de',
            child: const AcercaDeSection(),
          ),
        ],
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
