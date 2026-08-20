import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:supertonic_audiobook/features/modelo/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Pantalla de benchmark del motor TTS.
///
/// Muestra el último resultado, permite ejecutar un nuevo benchmark y
/// visualizar los tiempos por tamaño de texto.
class BenchmarkScreen extends ConsumerWidget {
  const BenchmarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final listo = ref.watch(modeloControllerProvider).listo;

    // Redirigir a /modelo si el modelo no está listo.
    if (!listo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Rutas.modelo);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.benchmark_titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () =>
                ref.read(benchmarkControllerProvider.notifier).recargar(),
          ),
        ],
      ),
      body: !listo
          ? Center(child: Text(t.benchmark_modelo_no_listo))
          : const _BenchmarkBody(),
    );
  }
}

class _BenchmarkBody extends ConsumerWidget {
  const _BenchmarkBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(benchmarkControllerProvider);
    final controller = ref.read(benchmarkControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Status card ---
        _StatusCard(estado: estado),

        const SizedBox(height: 16),

        // --- Size selection + Run button ---
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: estado.ejecutando ||
                        estado.tamaniosSeleccionados.isEmpty
                    ? null
                    : () => controller.ejecutar(),
                icon: const Icon(Icons.speed),
                label: Text(t.benchmark_btn_ejecutar),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: estado.ejecutando
                  ? null
                  : () => _mostrarSelectorTamanios(context, ref),
              icon: const Icon(Icons.tune),
              tooltip: t.benchmark_seleccionar_tamanios,
            ),
          ],
        ),

        // --- Selected sizes summary ---
        if (!estado.ejecutando)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${estado.tamaniosSeleccionados.length} tamaños seleccionados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        // --- Progress ---
        if (estado.ejecutando) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: estado.tamaniosSeleccionados.isEmpty
                ? 0
                : estado.pasoActual / estado.tamaniosSeleccionados.length,
          ),
          const SizedBox(height: 8),
          Text(
            t.benchmark_progreso(estado.pasoActual, estado.tamaniosSeleccionados.length, estado.tamanioActual),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => controller.cancelar(),
            child: Text(t.benchmark_btn_cancelar),
          ),
        ],

        // --- Results table ---
        if (estado.resultado != null) ...[
          const SizedBox(height: 24),
          _ResultsTable(resultado: estado.resultado!),
          const SizedBox(height: 8),
          Text(
            t.benchmark_ultima_corrida(
              _formatoFecha(estado.resultado!.fecha),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        // --- History ---
        if (estado.historial.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            t.historial_titulo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _HistorialTable(historial: estado.historial),
        ] else ...[
          const SizedBox(height: 24),
          Text(
            t.historial_vacio,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        // --- Error ---
        if (estado.error != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                estado.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet for multi-selecting benchmark sizes.
void _mostrarSelectorTamanios(BuildContext context, WidgetRef ref) {
  final t = AppLocalizations.of(context)!;
  final estado = ref.read(benchmarkControllerProvider);
  final controller = ref.read(benchmarkControllerProvider.notifier);

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.benchmark_seleccionar_tamanios,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tam in estado.tamaniosDisponibles)
                  FilterChip(
                    label: Text('$tam'),
                    selected:
                        estado.tamaniosSeleccionados.contains(tam),
                    onSelected: (_) => controller.toggleTamanio(tam),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(t.cerrar),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.estado});

  final BenchmarkEstado estado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final resultado = estado.resultado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resultado != null
                  ? t.benchmark_avg_chars_sec(
                      resultado.avgCharsPerSec.toStringAsFixed(1),
                    )
                  : t.benchmark_sin_datos,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.resultado});

  final BenchmarkResult resultado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final entradas = resultado.tamanios.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return DataTable(
      columns: [
        DataColumn(label: Text(t.benchmark_tab_tamano)),
        DataColumn(label: Text(t.benchmark_tab_tiempo)),
        DataColumn(label: Text(t.benchmark_tab_chars_seg)),
      ],
      rows: [
        for (final entrada in entradas)
          DataRow(cells: [
            DataCell(Text('${entrada.key} chars')),
            DataCell(Text(_formatearDuracion(entrada.value / 1000))),
            DataCell(Text(
              (entrada.key / (entrada.value / 1000)).toStringAsFixed(1),
            )),
          ]),
      ],
    );
  }
}

class _HistorialTable extends StatelessWidget {
  const _HistorialTable({required this.historial});

  final List<ConversionEntry> historial;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SizedBox(
      height: 240,
      child: DataTable(
        columns: [
          DataColumn(label: Text(t.historial_col_palabras)),
          DataColumn(label: Text(t.historial_col_segmentos)),
          DataColumn(label: Text(t.historial_col_duracion)),
        ],
        rows: [
          for (final entry in historial)
            DataRow(cells: [
              DataCell(Text('${entry.caracteres}')),
              DataCell(Text('${entry.segmentos}')),
              DataCell(Text(_formatearDuracion(entry.duracionAudioSeg))),
            ]),
        ],
      ),
    );
  }
}

/// Formats duration as "Xh - Y min - Z seg" / "Y min - Z seg" / "Z seg".
String _formatearDuracion(double segundos) {
  final total = segundos.floor();
  if (total < 60) return '$total seg';
  final minutos = total ~/ 60;
  final seg = total % 60;
  if (minutos < 60) return '$minutos min - $seg seg';
  final horas = minutos ~/ 60;
  final min = minutos % 60;
  return '$horas h - $min min - $seg seg';
}

String _formatoFecha(DateTime fecha) {
  return '${fecha.day}/${fecha.month}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';
}
