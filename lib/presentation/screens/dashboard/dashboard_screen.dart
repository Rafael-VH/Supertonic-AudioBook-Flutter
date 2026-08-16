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
/// la Biblioteca activa (DASH-1).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final modelo = ref.watch(modeloControllerProvider);
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
                      icono: Icons.library_music_outlined,
                      titulo: t.dashboard_procesar_sueltos,
                      descripcion: t.dashboard_procesar_sueltos_desc,
                      onTap: () => context.push(Rutas.seleccion),
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
                _FilaEstadoModelo(
                  estado: modelo,
                  onVerificar: () =>
                      ref.read(modeloControllerProvider.notifier).verificar(),
                ),
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

/// Línea de estado del modelo: veredicto actual ("descargado" / "sin
/// descargar") con un botón para re-verificar en disco. Discreta: texto chico
/// sobre `onSurfaceVariant`. (La elevación a Card con CTA/progreso es WO-4b.)
class _FilaEstadoModelo extends StatelessWidget {
  const _FilaEstadoModelo({required this.estado, required this.onVerificar});

  final ModeloEstado estado;
  final VoidCallback onVerificar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colores = Theme.of(context).colorScheme;
    final estilo = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colores.onSurfaceVariant);

    // Al arrancar con preferencia guardada, `listo` llega antes de que la
    // verificación de fondo termine: no mostrar el spinner sobre un
    // "descargado" ya publicado.
    final verificando = estado.verificando && !estado.listo;
    final String estadoTexto;
    if (verificando) {
      estadoTexto = t.dashboard_modelo_verificando;
    } else if (estado.listo) {
      estadoTexto = t.dashboard_modelo_descargado;
    } else {
      estadoTexto = t.dashboard_modelo_sin_descargar;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (verificando)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: t.refrescar,
            onPressed: onVerificar,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        const SizedBox(width: 8),
        Text('${t.dashboard_modelos}$estadoTexto', style: estilo),
      ],
    );
  }
}
