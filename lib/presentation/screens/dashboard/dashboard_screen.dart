import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Pantalla principal tras el onboarding. Muestra las tres funciones de la
/// app: convertir archivos a audio (funcional) y dos en camino (placeholders).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.dashboard_titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.ajustes,
            onPressed: () => context.push(Rutas.settings),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.dashboard_bienvenida,
                  style: texto.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _BotonFuncion(
                  icono: Icons.auto_awesome_outlined,
                  titulo: t.dashboard_procesar,
                  descripcion: t.dashboard_procesar_desc,
                  onTap: () => context.push(Rutas.home),
                ),
                const SizedBox(height: 16),
                _BotonFuncion(
                  icono: Icons.library_music_outlined,
                  titulo: t.dashboard_opcion2,
                  descripcion: t.dashboard_opcion2_desc,
                  onTap: null,
                ),
                const SizedBox(height: 16),
                _BotonFuncion(
                  icono: Icons.favorite_outline,
                  titulo: t.dashboard_opcion3,
                  descripcion: t.dashboard_opcion3_desc,
                  onTap: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de función del dashboard: icono, título, descripción y flecha.
/// Con [onTap] null queda deshabilitada (placeholder de función futura).
class _BotonFuncion extends StatelessWidget {
  const _BotonFuncion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final habilitado = onTap != null;

    return Card(
      elevation: 0,
      color: colores.surfaceContainerHighest.withValues(alpha: habilitado ? 0.5 : 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colores.primaryContainer.withValues(alpha: habilitado ? 1 : 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: habilitado
                      ? colores.onPrimaryContainer
                      : colores.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: habilitado ? null : colores.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: habilitado ? null : colores.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: habilitado ? colores.primary : colores.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
