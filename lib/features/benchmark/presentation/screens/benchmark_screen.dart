import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supertonic_audiobook/features/benchmark/domain/entities/benchmark_result.dart';
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
      appBar: AppBar(title: Text(t.benchmark_titulo)),
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

        // --- Run button ---
        FilledButton.icon(
          onPressed: estado.ejecutando ? null : () => controller.ejecutar(),
          icon: const Icon(Icons.speed),
          label: Text(t.benchmark_btn_ejecutar),
        ),

        // --- Progress ---
        if (estado.ejecutando) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: estado.pasoActual / 6,
          ),
          const SizedBox(height: 8),
          Text(
            t.benchmark_progreso(estado.pasoActual, estado.tamanioActual),
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
            DataCell(Text('${(entrada.value / 1000).toStringAsFixed(1)}s')),
            DataCell(Text(
              (entrada.key / (entrada.value / 1000)).toStringAsFixed(1),
            )),
          ]),
      ],
    );
  }
}

String _formatoFecha(DateTime fecha) {
  return '${fecha.day}/${fecha.month}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';
}
