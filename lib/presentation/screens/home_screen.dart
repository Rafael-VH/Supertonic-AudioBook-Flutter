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

/// Umbral de ancho para mostrar los paneles lado a lado (Material 6.2, responsive).
const int umbralAncho = 900;

/// Altura mínima del área del panel móvil para que la lista llene el alto;
/// por debajo, el cuerpo apilado degrada a scroll para no desbordar.
/// Escala con el texto del sistema: las cards crecen con textScale alto.
double _alturaMinimaPanelApilado(BuildContext context) =>
    400 * MediaQuery.textScalerOf(context).scale(1);

/// Pantalla principal: carpetas, archivos `.md`, opciones de síntesis,
/// registro y la acción de procesar.
///
/// En desktop (>= [umbralAncho]) los paneles van lado a lado con scroll
/// propio; en móvil se apilan con la lista de archivos como protagonista y
/// una barra de acción inferior persistente (plan de mejora de interfaz).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final ladoAlado = MediaQuery.sizeOf(context).width >= umbralAncho;

    ref.listen(homeControllerProvider.select((s) => s.snackbar), (prev, msg) {
      if (msg == null) return;
      final paleta = PaletaExt.of(context)?.paleta;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg.texto),
          behavior: ladoAlado
              ? SnackBarBehavior.floating
              : SnackBarBehavior.fixed,
          backgroundColor: msg.esError
              ? (paleta?.error ?? Theme.of(context).colorScheme.error)
              : null,
        ),
      );
    });

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
          ? _CuerpoLadoAlado(estado: estado, controller: controller, t: t)
          : _CuerpoApilado(estado: estado, controller: controller, t: t),
      bottomNavigationBar: ladoAlado
          ? null
          : _BarraAccion(
              estado: estado,
              controller: controller,
              t: t,
            ),
    );
  }
}

/// Desktop: dos paneles lado a lado, cada uno con sus cards.
class _CuerpoLadoAlado extends StatelessWidget {
  const _CuerpoLadoAlado({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _PanelEntrada(
              estado: estado,
              controller: controller,
              t: t,
              listaExpandida: false,
            ),
          ),
          Expanded(
            child: _PanelSintesis(
              estado: estado,
              controller: controller,
              t: t,
              conBotones: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Móvil: la lista de archivos llena el alto; opciones y registro quedan
/// colapsados y la acción principal vive en la barra inferior.
class _CuerpoApilado extends StatelessWidget {
  const _CuerpoApilado({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight >= _alturaMinimaPanelApilado(context)) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _PanelEntrada(
                    estado: estado,
                    controller: controller,
                    t: t,
                    listaExpandida: true,
                  ),
                );
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _PanelEntrada(
                    estado: estado,
                    controller: controller,
                    t: t,
                    listaExpandida: false,
                  ),
                ),
              );
            },
          ),
        ),
        _ExpansionOpciones(
          estado: estado,
          controller: controller,
          t: t,
        ),
        _ExpansionRegistro(
          estado: estado,
          controller: controller,
          t: t,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Barra de acción persistente (móvil): progreso + Procesar siempre visibles,
/// Cancelar solo durante la ejecución.
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final hayTrabajo = estado.ejecutando || estado.progresoTotal > 0;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hayTrabajo) ...[
                BarraProgreso(
                  actual: estado.progresoActual,
                  total: estado.progresoTotal,
                ),
                const SizedBox(height: 8),
              ],
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
                  if (estado.ejecutando) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.cancelar(t),
                        icon: const Icon(Icons.stop),
                        label: Text(t.btn_cancelar),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel de entrada: carpetas de origen/salida y lista de archivos.
class _PanelEntrada extends StatelessWidget {
  const _PanelEntrada({
    required this.estado,
    required this.controller,
    required this.t,
    required this.listaExpandida,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;
  final bool listaExpandida;

  @override
  Widget build(BuildContext context) {
    final habilitado = !estado.ejecutando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listaExpandida)
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: _CardCarpetas(
                estado: estado,
                habilitado: habilitado,
                onExaminarIn: controller.examinarCarpetaIn,
                onExaminarOut: controller.examinarCarpetaOut,
              ),
            ),
          )
        else
          _CardCarpetas(
            estado: estado,
            habilitado: habilitado,
            onExaminarIn: controller.examinarCarpetaIn,
            onExaminarOut: controller.examinarCarpetaOut,
          ),
        const SizedBox(height: 16),
        if (listaExpandida)
          Expanded(
            child: _CardArchivos(
              estado: estado,
              habilitado: habilitado,
              listaExpandida: listaExpandida,
              onRefrescar: controller.cargarArchivos,
              onTodo: controller.seleccionarTodo,
              onNada: controller.limpiarSeleccion,
              onAlternar: controller.alternarSeleccion,
            ),
          )
        else
          _CardArchivos(
            estado: estado,
            habilitado: habilitado,
            listaExpandida: listaExpandida,
            onRefrescar: controller.cargarArchivos,
            onTodo: controller.seleccionarTodo,
            onNada: controller.limpiarSeleccion,
            onAlternar: controller.alternarSeleccion,
          ),
      ],
    );
  }
}

/// Cards de carpetas de origen y salida.
class _CardCarpetas extends StatelessWidget {
  const _CardCarpetas({
    required this.estado,
    required this.habilitado,
    required this.onExaminarIn,
    required this.onExaminarOut,
  });

  final HomeEstado estado;
  final bool habilitado;
  final VoidCallback onExaminarIn;
  final VoidCallback onExaminarOut;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.carpeta_origen,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _FilaCarpeta(
              ruta: estado.carpetaIn,
              onExaminar: habilitado ? onExaminarIn : null,
            ),
            const SizedBox(height: 16),
            Text(t.salida_audio,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _FilaCarpeta(
              ruta: estado.carpetaOut,
              onExaminar: habilitado ? onExaminarOut : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de una carpeta: ruta (ellipsis + tooltip) y botón Examinar.
class _FilaCarpeta extends StatelessWidget {
  const _FilaCarpeta({required this.ruta, required this.onExaminar});

  final String ruta;
  final VoidCallback? onExaminar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: ruta,
            child: Text(
              ruta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onExaminar,
          icon: const Icon(Icons.folder_open),
          label: Text(t.examinar),
        ),
      ],
    );
  }
}

/// Card de archivos encontrados con su lista de selección.
class _CardArchivos extends StatelessWidget {
  const _CardArchivos({
    required this.estado,
    required this.habilitado,
    required this.listaExpandida,
    required this.onRefrescar,
    required this.onTodo,
    required this.onNada,
    required this.onAlternar,
  });

  final HomeEstado estado;
  final bool habilitado;
  final bool listaExpandida;
  final VoidCallback onRefrescar;
  final VoidCallback onTodo;
  final VoidCallback onNada;
  final ValueChanged<String> onAlternar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sel = estado.seleccion.length;
    final total = estado.archivos.length;
    final etiquetaConteo = sel > 0
        ? t.conteo_seleccionados(sel, total)
        : total > 0
            ? t.conteo_archivos(total)
            : t.conteo_sin;

    final lista = estado.archivos.isEmpty
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
                seleccionado: estado.seleccion.contains(archivo.ruta),
                habilitado: habilitado,
                onChanged: (_) => onAlternar(archivo.ruta),
              );
            },
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.archivos_encontrados,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: t.todo,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.done_all),
                  onPressed: habilitado ? onTodo : null,
                ),
                IconButton(
                  tooltip: t.nada,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.deselect),
                  onPressed: habilitado ? onNada : null,
                ),
                IconButton(
                  tooltip: t.refrescar,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh),
                  onPressed: habilitado ? onRefrescar : null,
                ),
              ],
            ),
            Text(etiquetaConteo,
                style: Theme.of(context).textTheme.bodySmall),
            Text(t.ayuda_seleccion,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (listaExpandida)
              Expanded(child: lista)
            else
              SizedBox(
                height: 280,
                child: lista,
              ),
          ],
        ),
      ),
    );
  }
}

/// Panel de síntesis: opciones y registro (solo desktop).
class _PanelSintesis extends StatelessWidget {
  const _PanelSintesis({
    required this.estado,
    required this.controller,
    required this.t,
    required this.conBotones,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;
  final bool conBotones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardOpciones(
            estado: estado,
            controller: controller,
          ),
          const SizedBox(height: 16),
          _CardRegistro(
            estado: estado,
            controller: controller,
            conBotones: conBotones,
          ),
        ],
      ),
    );
  }
}

/// Contenido de las opciones de síntesis (formato, voz, sliders, idioma).
class _ContenidoOpciones extends StatelessWidget {
  const _ContenidoOpciones({
    required this.estado,
    required this.controller,
  });

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final habilitado = !estado.ejecutando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        Text(t.voz, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: estado.voz,
          decoration: InputDecoration(
            helperText: t.modelo_supertonic,
            helperStyle: Theme.of(context).textTheme.bodySmall,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: [
            for (final v in voces)
              DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: habilitado ? (v) => controller.cambiarVoz(v!) : null,
        ),
        const SizedBox(height: 16),
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
                onChanged:
                    habilitado ? controller.cambiarSpeed : null,
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
        Text(t.idioma_voz,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: estado.langVoz,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: [
            for (final l in languagesVoz)
              DropdownMenuItem(
                value: l,
                child: Text(
                  l == 'na' ? t.idioma_voz_auto : idiomasVozNativos[l] ?? l,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: habilitado
              ? (v) => controller.cambiarLangVoz(v!)
              : null,
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: habilitado && !estado.probandoVoz
              ? () => controller.escuchar(t)
              : null,
          icon: const Icon(Icons.headphones),
          label: Text(t.escuchar),
        ),
      ],
    );
  }
}

/// Card de opciones de síntesis (desktop).
class _CardOpciones extends StatelessWidget {
  const _CardOpciones({required this.estado, required this.controller});

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.opciones_sintesis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _ContenidoOpciones(estado: estado, controller: controller),
          ],
        ),
      ),
    );
  }
}

/// Card de registro: log, estado, progreso y (desktop) botones de acción.
class _CardRegistro extends StatelessWidget {
  const _CardRegistro({
    required this.estado,
    required this.controller,
    required this.conBotones,
  });

  final HomeEstado estado;
  final HomeController controller;
  final bool conBotones;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
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
            if (conBotones) ...[
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
          ],
        ),
      ),
    );
  }
}

/// Opciones de síntesis colapsables (móvil).
class _ExpansionOpciones extends StatelessWidget {
  const _ExpansionOpciones({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ExpansionTile(
        title: Text(t.opciones_sintesis,
            style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _ContenidoOpciones(estado: estado, controller: controller),
        ],
      ),
    );
  }
}

/// Registro colapsable (móvil), autoexpandido durante la ejecución.
class _ExpansionRegistro extends StatelessWidget {
  const _ExpansionRegistro({
    required this.estado,
    required this.controller,
    required this.t,
  });

  final HomeEstado estado;
  final HomeController controller;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ExpansionTile(
        title: Text(t.registro,
            style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _ContenidoRegistro(estado: estado, controller: controller),
        ],
      ),
    );
  }
}

/// Contenido del registro: log, estado y progreso.
class _ContenidoRegistro extends StatelessWidget {
  const _ContenidoRegistro({
    required this.estado,
    required this.controller,
  });

  final HomeEstado estado;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
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
      ],
    );
  }
}
