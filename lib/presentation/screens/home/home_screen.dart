import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Hub principal que muestra las funciones disponibles de la app.
/// Se embebe en el tab 0 del [DashboardScreen].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _FunctionCard(
              icon: Icons.audiotrack_outlined,
              selectedIcon: Icons.audiotrack,
              title: t.dashboard_procesar,
              description: t.dashboard_procesar_desc,
              onTap: () => context.push(Rutas.home),
            ),
            const SizedBox(height: 12),
            _FunctionCard(
              icon: Icons.edit_outlined,
              selectedIcon: Icons.edit,
              title: t.home_editor_metadata,
              description: t.home_editor_metadata_desc,
              onTap: () => context.push(Rutas.editorMetadata),
            ),
            const SizedBox(height: 12),
            _FunctionCard(
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

class _FunctionCard extends StatelessWidget {
  const _FunctionCard({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnTap = enabled ? onTap : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: effectiveOnTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? null
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.38),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.38),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
