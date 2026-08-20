import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/conversion_entry.dart';
import 'package:supertonic_audiobook/features/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:supertonic_audiobook/features/modelo/presentation/controllers/modelo_controller.dart';
import 'package:supertonic_audiobook/presentation/controllers/providers.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/routing/app_router.dart';

/// Pantalla de benchmark del motor TTS.
///
/// Tabla fija de 6 filas (2500–15000) con botón individual por fila.
class BenchmarkScreen extends ConsumerWidget {
  const BenchmarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final listo = ref.watch(modeloControllerProvider).listo;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Tabla fija de benchmark ---
        _BenchmarkTable(estado: estado),

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

        // --- Historial ---
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
      ],
    );
  }
}

/// Tabla fija: 4 columnas × 6 filas.
class _BenchmarkTable extends StatelessWidget {
  const _BenchmarkTable({required this.estado});

  final BenchmarkEstado estado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        t.benchmark_tab_tamano,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        t.benchmark_tab_tiempo,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        t.benchmark_tab_chars_seg,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            const Divider(height: 1),
            // Rows
            for (final tamanio in benchmarkTamanios) ...[
              _FilaBenchmark(
                tamanio: tamanio,
                resultado: estado.resultados[tamanio],
                ejecutando: estado.filaEjecutando == tamanio,
                bloqueado: estado.ejecutando,
              ),
              if (tamanio != benchmarkTamanios.last) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaBenchmark extends ConsumerWidget {
  const _FilaBenchmark({
    required this.tamanio,
    required this.resultado,
    required this.ejecutando,
    required this.bloqueado,
  });

  final int tamanio;
  final FilaBenchmark? resultado;
  final bool ejecutando;
  final bool bloqueado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Tamaño
          Expanded(
            flex: 2,
            child: Center(child: Text('$tamanio')),
          ),
          // Tiempo
          Expanded(
            flex: 3,
            child: Center(
              child: ejecutando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(resultado != null
                      ? _formatearDuracion(resultado!.tiempoMs / 1000)
                      : '—'),
            ),
          ),
          // Chars/seg
          Expanded(
            flex: 3,
            child: Center(
              child: ejecutando
                  ? const SizedBox.shrink()
                  : Text(resultado != null
                      ? '${resultado!.charsSeg.toStringAsFixed(1)}'
                      : '—'),
            ),
          ),
          // Botón
          SizedBox(
            width: 56,
            child: Center(
              child: IconButton(
                onPressed: (ejecutando || bloqueado)
                    ? null
                    : () => ref
                        .read(benchmarkControllerProvider.notifier)
                        .ejecutarFila(tamanio),
                icon: ejecutando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              tooltip: ejecutando ? 'Procesando...' : 'Benchmark $tamanio',
            ),
          ),
        ],
      ),
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
