import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supertonic_audiobook/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';
import 'package:supertonic_audiobook/presentation/theme/app_theme.dart';
import 'package:supertonic_audiobook/presentation/theme/paleta.dart';

/// Umbral de ancho desde el cual las cards de función van en grid de 2
/// columnas (DASH-9). Debajo se apilan en una columna.
const double _umbralGrid = 600;

/// Alturas de celda del grid (DASH-9): uniformes para que las cards de una
/// fila queden iguales. Texto acotado en la card (título 2 líneas, descripción
/// 4) para que la altura sea estable también con el font de test (Ahem).
const double _alturaCardColumna = 156;
const double _alturaCardGrid = 168;

/// Pantalla principal tras el onboarding. Muestra un hero de bienvenida
/// (DASH-8) y las tres funciones de la app como cards del `cardTheme` global
/// con acentos `PaletaExt` (DASH-3): convertir archivos, procesar sueltos y
/// la Biblioteca activa (DASH-1). El estado del modelo NO se observa acá:
/// vive aislado en `_CardEstadoModelo` (DASH-7).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final dosColumnas = MediaQuery.sizeOf(context).width >= _umbralGrid;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero de bienvenida (DASH-8): título + subtítulo destacados
                // al tope, antes de las cards.
                Text(
                  t.dashboard_bienvenida,
                  style: texto.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t.dashboard_bienvenida_sub,
                  style: texto.bodyMedium?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: dosColumnas ? 2 : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: dosColumnas
                        ? _alturaCardGrid
                        : _alturaCardColumna,
                  ),
                  children: [
                    _CardFuncion(
                      icono: Icons.auto_awesome_outlined,
                      titulo: t.dashboard_procesar,
                      descripcion: t.dashboard_procesar_desc,
                      onTap: () => context.push(Rutas.home),
                    ),
                    _CardFuncion(
                      icono: Icons.library_books_outlined,
                      titulo: t.dashboard_biblioteca,
                      descripcion: t.dashboard_biblioteca_desc,
                      onTap: () => context.push(Rutas.biblioteca),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _CardEstadoModelo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de función del dashboard: hereda color, shape y elevación del
/// `cardTheme` global (DASH-3, sin override local); el círculo del icono usa
/// los acentos y biseles de `PaletaExt` (primarioClaro en material,
/// primarioLuz/primarioSombra en neumo/skeuo) y el ripple/hover es
/// `primaryContainer` al 12 %.
class _CardFuncion extends StatelessWidget {
  const _CardFuncion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final ext = PaletaExt.of(context)!;
    final esMaterial = ext.estilo == AppEstilo.material;
    final p = ext.paleta;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: colores.primaryContainer.withValues(alpha: 0.12),
        overlayColor: WidgetStatePropertyAll(
          colores.primaryContainer.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: esMaterial ? p.primarioClaro : p.primarioLuz,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  color: esMaterial
                      ? colores.onPrimaryContainer
                      : p.primarioSombra,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colores.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de estado del modelo: único lugar del dashboard que observa
/// `modeloControllerProvider` (DASH-7, watch aislado con `select()` implícito
/// al vivir en su propio widget). Misma familia visual que `_CardFuncion`
/// (cardTheme + PaletaExt, sin color/shape/elevación propios).
///
/// El contenido refleja el estado VERAZ (DASH-5): `descargando` muestra el
/// progreso real (nunca "sin descargar"), `verificando` un spinner, `listo`
/// "descargado" y `error` el mensaje con el CTA de reintento disponible.
/// El CTA navega a `/modelo` con el origen (DASH-6, el redirect formal es
/// WO-5) y el refresh mide ≥48×48 (DASH-10).
class _CardEstadoModelo extends ConsumerWidget {
  const _CardEstadoModelo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final estado = ref.watch(modeloControllerProvider);

    // Al arrancar con preferencia guardada, `listo` llega antes de que la
    // verificación de fondo termine: no mostrar el spinner sobre un
    // "descargado" ya publicado.
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

    // CTA visible cuando el modelo no está listo y no hay nada en curso
    // (DASH-6). Tras un error el CTA vuelve a estar disponible para
    // reintentar (DASH-5).
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
                    // Con error, el mensaje ocupa el título (más veraz que un
                    // "sin descargar" contradictorio al lado del error).
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
