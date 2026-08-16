import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/presentation/controllers/biblioteca_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';

/// Pantalla Biblioteca (BIB-1..BIB-5): lista los audiolibros generados en la
/// carpeta de salida agrupados por libro, con play/pausa por tile, estado
/// vacío con acción a la conversión y estado de error con reintentar.
/// Reproduce solo vía el contrato `ReproductorAudio` (nunca `just_audio`,
/// BIB-6). Las cards heredan el `cardTheme` global (DASH-3).
class BibliotecaScreen extends ConsumerWidget {
  const BibliotecaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(bibliotecaControllerProvider);
    final controller = ref.read(bibliotecaControllerProvider.notifier);

    // BIB-5: un error nuevo (p. ej. reproducción fallida) se avisa en una
    // SnackBar con el color de error de la paleta (patrón seleccion_screen).
    ref.listen(bibliotecaControllerProvider.select((s) => s.error), (
      previo,
      error,
    ) {
      if (error == null) return;
      final paleta = PaletaExt.of(context)?.paleta;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.biblioteca_error(error)),
          backgroundColor: paleta?.error ?? Theme.of(context).colorScheme.error,
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.biblioteca_titulo)),
      body: SafeArea(
        child: _Cuerpo(estado: estado, controller: controller, t: t),
      ),
    );
  }
}

/// Cuerpo por estado del controller (D3): error → lista vacía.
class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final BibliotecaEstado estado;
  final BibliotecaController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final error = estado.error;
    if (error != null) {
      return _EstadoError(
        error: error,
        t: t,
        onReintentar: controller.recargar,
      );
    }
    if (estado.vacio) {
      return _EstadoVacio(t: t, onIrAConvertir: () => context.push(Rutas.home));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: estado.libros.length,
      itemBuilder: (context, i) {
        final libro = estado.libros[i];
        final reproduciendo =
            estado.reproduciendoRuta == libro.rutaPrioritaria &&
            !estado.pausado;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              reproduciendo
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            title: Text(libro.titulo),
            subtitle: Text(libro.formatoPrioritario.toUpperCase()),
            trailing: IconButton(
              tooltip: reproduciendo ? t.biblioteca_pausa : t.biblioteca_play,
              icon: Icon(reproduciendo ? Icons.pause : Icons.play_arrow),
              // DASH-10: área táctil mínima de 48dp.
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => controller.alternarReproduccion(libro),
            ),
            onTap: () => controller.alternarReproduccion(libro),
          ),
        );
      },
    );
  }
}

/// Estado de error: mensaje localizado + botón reintentar (`recargar()`).
class _EstadoError extends StatelessWidget {
  const _EstadoError({
    required this.error,
    required this.t,
    required this.onReintentar,
  });

  final String error;
  final AppLocalizations t;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              t.biblioteca_error(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: Text(t.refrescar),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío (BIB-4): mensaje + acción que lleva a la conversión.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.t, required this.onIrAConvertir});

  final AppLocalizations t;
  final VoidCallback onIrAConvertir;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              t.biblioteca_vacio,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onIrAConvertir,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(t.biblioteca_vacio_accion),
            ),
          ],
        ),
      ),
    );
  }
}
