import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/constants/producto.dart';
import '../../domain/use_cases/formato.dart';
import '../constants/muestra_voz.dart';
import '../controllers/home_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/archivo_tile.dart';
import '../widgets/barra_progreso.dart';
import 'settings_screen.dart';

/// Umbral de ancho para mostrar los paneles lado a lado (§6.2, responsive).
const int umbralAncho = 900;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    ref.listen(homeControllerProvider.select((s) => s.snackbar), (prev, msg) {
      if (msg == null) return;
      final paleta = PaletaExt.of(context)?.paleta;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg.texto),
          backgroundColor: msg.esError
              ? (paleta?.error ?? Theme.of(context).colorScheme.error)
              : null,
        ),
      );
    });

    final ladoAlado = MediaQuery.sizeOf(context).width >= umbralAncho;

    final panelEntrada = _PanelEntrada(
      estado: estado,
      onExaminarIn: controller.examinarCarpetaIn,
      onExaminarOut: controller.examinarCarpetaOut,
      onRefrescar: controller.cargarArchivos,
      onTodo: controller.seleccionarTodo,
      onNada: controller.limpiarSeleccion,
      onAlternar: controller.alternarSeleccion,
    );
    final panelSintesis = _PanelSintesis(
      estado: estado,
      controller: controller,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ventana_titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.ajustes,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ladoAlado
          ? SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: panelEntrada),
                  Expanded(child: panelSintesis),
                ],
              ),
            )
          : ListView(
              children: [panelEntrada, panelSintesis],
            ),
    );
  }
}

class _PanelEntrada extends StatelessWidget {
  const _PanelEntrada({
    required this.estado,
    required this.onExaminarIn,
    required this.onExaminarOut,
    required this.onRefrescar,
    required this.onTodo,
    required this.onNada,
    required this.onAlternar,
  });

  final HomeEstado estado;
  final VoidCallback onExaminarIn;
  final VoidCallback onExaminarOut;
  final VoidCallback onRefrescar;
  final VoidCallback onTodo;
  final VoidCallback onNada;
  final ValueChanged<String> onAlternar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final habilitado = !estado.ejecutando;
    final sel = estado.seleccion.length;
    final total = estado.archivos.length;
    final etiquetaConteo = sel > 0
        ? t.conteo_seleccionados(sel, total)
        : total > 0
            ? t.conteo_archivos(total)
            : t.conteo_sin;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.carpeta_origen,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          estado.carpetaIn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: habilitado ? onExaminarIn : null,
                        icon: const Icon(Icons.folder_open),
                        label: Text(t.examinar),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(t.salida_audio,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          estado.carpetaOut,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: habilitado ? onExaminarOut : null,
                        icon: const Icon(Icons.folder_open),
                        label: Text(t.examinar),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.archivos_encontrados,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      TextButton(
                        onPressed: habilitado ? onTodo : null,
                        child: Text(t.todo),
                      ),
                      TextButton(
                        onPressed: habilitado ? onNada : null,
                        child: Text(t.nada),
                      ),
                      TextButton(
                        onPressed: habilitado ? onRefrescar : null,
                        child: Text(t.refrescar),
                      ),
                    ],
                  ),
                  Text(etiquetaConteo,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(t.ayuda_seleccion,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: estado.archivos.isEmpty
                        ? Center(
                            child: Text(t.conteo_sin,
                                style: Theme.of(context).textTheme.bodySmall),
                          )
                        : ListView.builder(
                            itemCount: estado.archivos.length,
                            itemBuilder: (context, i) {
                              final archivo = estado.archivos[i];
                              return ArchivoTile(
                                archivo: archivo,
                                seleccionado:
                                    estado.seleccion.contains(archivo.ruta),
                                habilitado: habilitado,
                                onChanged: (_) => onAlternar(archivo.ruta),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSintesis extends StatelessWidget {
  const _PanelSintesis({required this.estado, required this.controller});

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final habilitado = !estado.ejecutando;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.opciones_sintesis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // Formato (chips)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in formatosNativos)
                        FilterChip(
                          label: Text(f.toUpperCase()),
                          selected: estado.formatos.contains(f),
                          onSelected: habilitado
                              ? (_) => controller.alternarFormato(f)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Voz
                  Row(
                    children: [
                      Text(t.voz,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: estado.voz,
                        items: [
                          for (final v in voces)
                            DropdownMenuItem(value: v, child: Text(v)),
                        ],
                        onChanged: habilitado
                            ? (v) => controller.cambiarVoz(v!)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(t.modelo_supertonic,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pasos
                  Row(
                    children: [
                      Text(t.pasos,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: estado.steps.toDouble(),
                          min: 5,
                          max: 12,
                          divisions: 7,
                          label: '${estado.steps}',
                          onChanged: habilitado
                              ? (v) => controller.cambiarSteps(v.round())
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('${estado.steps}',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  Text(t.calidad_lento,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),

                  // Velocidad
                  Row(
                    children: [
                      Text(t.velocidad,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: estado.speed,
                          min: 0.7,
                          max: 2.0,
                          label: '${estado.speed.toStringAsFixed(2)}x',
                          onChanged: habilitado
                              ? controller.cambiarSpeed
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${estado.speed.toStringAsFixed(2)}x',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                  Text(t.rapido_lento,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),

                  // Idioma de la voz
                  Row(
                    children: [
                      Text(t.idioma_voz,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 12),
                      Flexible(
                        child: DropdownButton<String>(
                          value: estado.langVoz,
                          isExpanded: true,
                          items: [
                            for (final l in languagesVoz)
                              DropdownMenuItem(
                                value: l,
                                child: Text(
                                  l == 'na'
                                      ? t.idioma_voz_auto
                                      : idiomasVozNativos[l] ?? l,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: habilitado
                              ? (v) => controller.cambiarLangVoz(v!)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: habilitado && !estado.probandoVoz
                        ? () => controller.escuchar(t)
                        : null,
                    icon: const Icon(Icons.headphones),
                    label: Text(t.escuchar),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.registro,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: estado.lineasLog.isEmpty
                        ? const SizedBox.shrink()
                        : SingleChildScrollView(
                            reverse: true,
                            child: SelectableText(
                              estado.lineasLog.reversed.join('\n'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    estado.estado.isEmpty ? t.estado_listo : estado.estado,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  BarraProgreso(
                    actual: estado.progresoActual,
                    total: estado.progresoTotal,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: estado.ejecutando
                              ? null
                              : () => controller.procesar(t),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(t.btn_procesar),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: estado.ejecutando
                              ? () => controller.cancelar(t)
                              : null,
                          icon: const Icon(Icons.stop),
                          label: Text(t.btn_cancelar),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
