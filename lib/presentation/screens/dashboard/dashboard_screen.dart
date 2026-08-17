import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/screens/biblioteca/biblioteca_screen.dart';
import 'package:supertonic_audiobook/presentation/screens/home/home_screen.dart';

/// Shell principal de la app con BottomNavigationBar. Alterna entre
/// [HomeBody] (conversión) y [BibliotecaBody] (audiolibros generados).
/// El estado del modelo vive aislado en [_CardEstadoModelo] (DASH-7).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home: cuerpo de conversión + card de estado del modelo
          _HomeConModelo(t: t),
          // Biblioteca
          const BibliotecaBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.nav_home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_books_outlined),
            selectedIcon: const Icon(Icons.library_books),
            label: t.nav_biblioteca,
          ),
        ],
      ),
    );
  }
}

/// Wrapper que apila el [HomeBody] y la [_CardEstadoModelo] dentro de un
/// scroll. La card del modelo se muestra arriba del workspace de conversión
/// para que el usuario sepa si el modelo está disponible antes de procesar.
class _HomeConModelo extends StatelessWidget {
  const _HomeConModelo({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card de estado del modelo (aislada, watch propio → DASH-7)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _CardEstadoModelo(),
        ),
        // Cuerpo de conversión (HomeBody: acordeón + barra de acción)
        const Expanded(child: HomeBody()),
      ],
    );
  }
}

/// Card de estado del modelo: único lugar del dashboard que observa
/// `modeloControllerProvider` (DASH-7, watch aislado con `select()` implícito
/// al vivir en su propio widget).
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
