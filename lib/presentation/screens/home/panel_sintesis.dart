import 'package:flutter/material.dart';
import 'package:supertonic_audiobook/domain/constants/producto.dart';
import 'package:supertonic_audiobook/domain/use_cases/formato.dart';
import 'package:supertonic_audiobook/presentation/constants/muestra_voz.dart';
import 'package:supertonic_audiobook/presentation/controllers/home_controller.dart';
import 'package:supertonic_audiobook/presentation/l10n/app_localizations.dart';
import 'package:supertonic_audiobook/presentation/screens/home/card_registro.dart';

/// Panel de síntesis: opciones y registro (solo desktop).
class PanelSintesis extends StatelessWidget {
  const PanelSintesis({
    super.key,
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
          _CardOpciones(estado: estado, controller: controller),
          const SizedBox(height: 16),
          CardRegistro(
            estado: estado,
            controller: controller,
            conBotones: conBotones,
          ),
        ],
      ),
    );
  }
}

/// Opciones de síntesis colapsables (móvil).
class ExpansionOpciones extends StatelessWidget {
  const ExpansionOpciones({
    super.key,
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
        title: Text(
          t.opciones_sintesis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [_ContenidoOpciones(estado: estado, controller: controller)],
      ),
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
            Text(
              t.opciones_sintesis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ContenidoOpciones(estado: estado, controller: controller),
          ],
        ),
      ),
    );
  }
}

/// Contenido de las opciones de síntesis (formato, voz, sliders, idioma).
class _ContenidoOpciones extends StatelessWidget {
  const _ContenidoOpciones({required this.estado, required this.controller});

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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
          items: [
            for (final v in voces) DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: habilitado ? (v) => controller.cambiarVoz(v!) : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(t.pasos, style: Theme.of(context).textTheme.titleMedium),
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
              child: Text(
                '${estado.steps}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Text(t.calidad_lento, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(t.velocidad, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: estado.speed,
                min: 0.7,
                max: 2.0,
                label: '${estado.speed.toStringAsFixed(2)}x',
                onChanged: habilitado ? controller.cambiarSpeed : null,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${estado.speed.toStringAsFixed(2)}x',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Text(t.rapido_lento, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Text(t.idioma_voz, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: estado.langVoz,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
          onChanged: habilitado ? (v) => controller.cambiarLangVoz(v!) : null,
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
